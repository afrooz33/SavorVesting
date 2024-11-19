const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  // Get the signer (deployer) from the private key in .env
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  // Fetch contract factory for SavorVesting
  const SavorVesting = await ethers.getContractFactory("SavorVesting");

  // Get the USDT token address and deployer's address from .env
  const usdtAddress = process.env.USDT_ADDRESS;
  const deployerAddress = deployer.address;

  // Deploy the contract with the provided arguments
  const savorVesting = await SavorVesting.deploy(usdtAddress, deployerAddress);

  console.log("SavorVesting contract deployed to:", savorVesting.address);

  // Wait for the contract to be deployed
  await savorVesting.deployed();
  console.log("SavorVesting deployed at address:", savorVesting.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
