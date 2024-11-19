const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SavorVesting Contract", function () {
  let SavorVesting;
  let savorVesting;
  let owner;
  let addr1;
  let addr2;
  let usdtMock;
  let priceFeedMock;
  let tokenAmount = ethers.utils.parseUnits("1000", 18); // 1000 tokens

  const usdtAmount = ethers.utils.parseUnits("100", 6); // 100 USDT
  const bnbAmount = ethers.utils.parseUnits("1", 18); // 1 BNB

  beforeEach(async () => {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy USDT mock contract (this would be a mock of the USDT contract)
    const USDT = await ethers.getContractFactory("ERC20Mock");
    usdtMock = await USDT.deploy("USD Tether", "USDT", 6);

    // Deploy Chainlink mock price feed
    const MockAggregator = await ethers.getContractFactory("MockAggregator");
    priceFeedMock = await MockAggregator.deploy();

    // Deploy the SavorVesting contract
    const SavorVesting = await ethers.getContractFactory("SavorVesting");
    savorVesting = await SavorVesting.deploy(usdtMock.address, owner.address);

    // Transfer USDT to addr1
    await usdtMock.mint(addr1.address, usdtAmount);
  });

  describe("Deployment", function () {
    it("Should deploy the contract and set initial values", async function () {
      expect(await savorVesting.owner()).to.equal(owner.address);
      expect(await savorVesting.remainingToken()).to.equal(
        await savorVesting.totalSupply()
      );
    });
  });

  describe("Presale 1", function () {
    it("Should start presale 1 correctly", async function () {
      const endTime = (await ethers.provider.getBlock("latest")).timestamp + 3600;
      await savorVesting.preSale_1_Listing(endTime);

      const saleData = await savorVesting.pre_Sale_1_mapping(
        await savorVesting.address
      );

      expect(saleData.saleActive).to.equal(true);
      expect(saleData.endTime).to.be.gt(0);
    });

    it("Should allow buying tokens in presale 1 using USDT", async function () {
      const endTime = (await ethers.provider.getBlock("latest")).timestamp + 3600;
      await savorVesting.preSale_1_Listing(endTime);

      // Approve USDT transfer
      await usdtMock.connect(addr1).approve(savorVesting.address, usdtAmount);

      // Buy tokens using USDT
      await expect(
        savorVesting.connect(addr1).buyTokens(tokenAmount, 0)
      ).to.emit(savorVesting, "Token")
        .withArgs(tokenAmount);

      const userRecord = await savorVesting.checkTokens(
        savorVesting.address,
        addr1.address
      );
      expect(userRecord.amount).to.equal(tokenAmount);
    });

    it("Should allow buying tokens in presale 1 using BNB", async function () {
      const endTime = (await ethers.provider.getBlock("latest")).timestamp + 3600;
      await savorVesting.preSale_1_Listing(endTime);

      const cost = await savorVesting.getPrice_W_R_T_BNB(bnbAmount);

      // Buy tokens using BNB
      await expect(
        savorVesting.connect(addr1).buyTokens(tokenAmount, 1, { value: cost })
      ).to.emit(savorVesting, "bnb")
        .withArgs(cost);

      const userRecord = await savorVesting.checkTokens(
        savorVesting.address,
        addr1.address
      );
      expect(userRecord.amount).to.equal(tokenAmount);
    });

    it("Should revert if not enough tokens are available", async function () {
      const endTime = (await ethers.provider.getBlock("latest")).timestamp + 3600;
      await savorVesting.preSale_1_Listing(endTime);

      await expect(
        savorVesting.connect(addr1).buyTokens(ethers.utils.parseUnits("1000000", 18), 0)
      ).to.be.revertedWith("Not enough tokens available");
    });
  });

  describe("Claiming", function () {
    it("Should allow users to claim tokens after cliff period", async function () {
      const endTime = (await ethers.provider.getBlock("latest")).timestamp + 3600;
      await savorVesting.preSale_1_Listing(endTime);

      await usdtMock.connect(addr1).approve(savorVesting.address, usdtAmount);
      await savorVesting.connect(addr1).buyTokens(tokenAmount, 0);

      // Set startTime and trigger claim
      const startTime = (await ethers.provider.getBlock("latest")).timestamp + 3600;
      await savorVesting.startTimee(startTime);

      // Simulate the time after the cliff period
      await network.provider.send("evm_increaseTime", [3600 * 30]);
      await network.provider.send("evm_mine");

      await expect(savorVesting.connect(addr1).myClaim())
        .to.emit(savorVesting, "Transfer")
        .withArgs(ethers.constants.AddressZero, addr1.address, tokenAmount);
    });

    it("Should revert if trying to claim before cliff period", async function () {
      const endTime = (await ethers.provider.getBlock("latest")).timestamp + 3600;
      await savorVesting.preSale_1_Listing(endTime);

      await usdtMock.connect(addr1).approve(savorVesting.address, usdtAmount);
      await savorVesting.connect(addr1).buyTokens(tokenAmount, 0);

      // Set startTime and trigger claim
      const startTime = (await ethers.provider.getBlock("latest")).timestamp + 3600;
      await savorVesting.startTimee(startTime);

      await expect(savorVesting.connect(addr1).myClaim()).to.be.revertedWith(
        "clif period not ended"
      );
    });
  });

  describe("Pause and Unpause", function () {
    it("Should allow pausing and unpausing of contract", async function () {
      await savorVesting.pause();
      expect(await savorVesting.paused()).to.equal(true);

      await savorVesting.unpause();
      expect(await savorVesting.paused()).to.equal(false);
    });

    it("Should revert on paused contract during buy", async function () {
      await savorVesting.pause();
      await expect(
        savorVesting.connect(addr1).buyTokens(tokenAmount, 0)
      ).to.be.revertedWith("Pausable: paused");
    });
  });
});
