// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract SavorVesting is ERC20, ERC20Burnable, Pausable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private numberOfTransactions;
    using SafeERC20 for IERC20;
    bool public IsClaim;
    address AddminAddress;
    address USDT;
    address immutable UsdcContract;
    uint256 currencyinUSDT;
    uint256 cost;
    uint256 constant scale = 1e18;
    uint256 public remainingToken;
    uint256 public startTime;
    uint256 private total_periods = 18; // months
    uint256 private cliff = 3; // months
    uint256 private constant seconds_in_month = 30 * 24 * 60 * 60; //seconds in one month
    // uint256 private constant seconds_in_month = 20; //seconds in one month
    uint256 claimCount;
    bool private active_1;
    bool private active_2;
    bool private active_3;
    int256 private BnbPrice;
    AggregatorV3Interface internal priceFeed;
    uint256 public TOKEN_PRICE;
    uint256 _per;

    event Token(uint256 value);

    event bnb(uint256 value);

    error InsufficientTokensAvailable();
    error NotTimeToMint2();
    error LogicalIssue();
    error NotTimeToMint3();
    error NotTimeToMintPublicRound();
    error Sale1Active();
    error Sale2NotActive();
    struct userRecord {
        address user;
        uint256 amount;
        uint256 currency;
        uint256 cost;
        bool claim;
        currency choice;
    }
    struct userDetail {
        uint256 currency;
        uint256 amount;
        uint256 time;
        uint256 preSale_1;
        uint256 preSale_2;
        uint256 preSale_3;
        address user;
        address contractAddress;
        bool firstClaim;
        uint256 claimed_periods;
        uint256 last_claimed_at;
        uint256 first_claimed_at;
    }
    struct Sale_1_tokens {
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        uint256 supplyAvailable;
        uint256 tokenCliamed;
        address user;
        bool saleActive;
    }
    mapping(address => mapping(uint256 => userRecord)) public TokenRecord;
    mapping(address => mapping(address => userDetail)) public checkTokens;
    mapping(currency => uint256) public _currencyCoice;
    mapping(address => uint256) public NumberOfBuying;
    mapping(address => uint256) public userTokens;
    mapping(address => uint256) public lastClaimedPeriodForPreSale1;
    mapping(address => uint256) public lastClaimedPeriodForPublicRound;
    mapping(address => Sale_1_tokens) public pre_Sale_1_mapping;
    mapping(address => Sale_1_tokens) public pre_Sale_2_mapping;
    mapping(address => Sale_1_tokens) public pre_Sale_3_mapping;
    mapping(address => Sale_1_tokens) public public_Round_mapping;
    mapping(address => uint256) private userToken_1;
    mapping(address => uint256) private userToken_2;
    mapping(address => uint256) private userToken_3;

    enum currency {
        USDT,
        BNB
    }

    constructor(address _UsdtContract, address ownerAddress)
        ERC20("SavorVesting Tokens", "SAV")
        Ownable(ownerAddress)
    {
        _mint(msg.sender, 1000000000 * 10**decimals());
        priceFeed = AggregatorV3Interface(
            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        );
        BnbPrice = getLatestPrice();
        UsdcContract = _UsdtContract;
        remainingToken = totalSupply();
    }

    function AdminAddToken(uint256 _amount) public onlyOwner {
        IERC20(address(this)).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    function transferTokens(address user, uint256 amount) external onlyOwner {
        IERC20(address(this)).transfer(user, amount);
    }

    function preSale_1_Listing(uint256 endTime) external onlyOwner {
        require(active_1 == false, "Sale already Done");

        if (pre_Sale_2_mapping[address(this)].saleActive) {
            if (
                block.timestamp > pre_Sale_2_mapping[address(this)].endTime ||
                pre_Sale_2_mapping[address(this)].supplyAvailable == 0
            ) {
                pre_Sale_2_mapping[address(this)].saleActive = false;
            }
        }

        if (pre_Sale_3_mapping[address(this)].saleActive) {
            if (
                block.timestamp > pre_Sale_3_mapping[address(this)].endTime ||
                pre_Sale_3_mapping[address(this)].supplyAvailable == 0
            ) {
                pre_Sale_3_mapping[address(this)].saleActive = false;
            }
        }

        if (
            pre_Sale_2_mapping[address(this)].saleActive ||
            pre_Sale_3_mapping[address(this)].saleActive
        ) {
            revert NotTimeToMint2();
        }
        pre_Sale_1_mapping[address(this)] = Sale_1_tokens(
            10000000000000000,
            block.timestamp,
            endTime,
            100000000000000000000000000,
            0,
            msg.sender,
            true
        );
        currencyinUSDT = pre_Sale_1_mapping[address(this)].price;
        active_1 = true;
        BnbPrice = getLatestPrice(); // BNB price with 8 decimals
        TOKEN_PRICE = (currencyinUSDT * 10**8) / uint256(BnbPrice);
    }

    function preSale_2_Listing(uint256 endTime) external  {
        require(active_2 == false, "Sale already Done");

        if (pre_Sale_1_mapping[address(this)].saleActive) {
            if (
                block.timestamp > pre_Sale_1_mapping[address(this)].endTime ||
                pre_Sale_1_mapping[address(this)].supplyAvailable == 0
            ) {
                pre_Sale_1_mapping[address(this)].saleActive = false;
            }
        }

        if (pre_Sale_3_mapping[address(this)].saleActive) {
            if (
                block.timestamp > pre_Sale_3_mapping[address(this)].endTime ||
                pre_Sale_3_mapping[address(this)].supplyAvailable == 0
            ) {
                pre_Sale_3_mapping[address(this)].saleActive = false;
            }
        }

        //  Round cannot be started when another is acticted

        if (
            pre_Sale_1_mapping[address(this)].saleActive ||
            pre_Sale_3_mapping[address(this)].saleActive
        ) {
            revert NotTimeToMint2();
        }

        pre_Sale_2_mapping[address(this)] = Sale_1_tokens(
            20000000000000000,
            block.timestamp,
            endTime,
            30000000000000000000000000,
            0,
            msg.sender,
            true
        );
        currencyinUSDT = pre_Sale_2_mapping[address(this)].price;

        active_2 == true;
        BnbPrice = getLatestPrice(); // BNB price with 8 decimals
        TOKEN_PRICE = (currencyinUSDT * 10**8) / uint256(BnbPrice);
    }

    function preSale_3_Listing(uint256 endTime) external  {
        require(active_3 == false, "Sale already Done");

        if (pre_Sale_1_mapping[address(this)].saleActive) {
            if (
                block.timestamp > pre_Sale_1_mapping[address(this)].endTime ||
                pre_Sale_1_mapping[address(this)].supplyAvailable == 0
            ) {
                pre_Sale_1_mapping[address(this)].saleActive = false;
            }
        }

        if (pre_Sale_2_mapping[address(this)].saleActive) {
            if (
                block.timestamp > pre_Sale_2_mapping[address(this)].endTime ||
                pre_Sale_2_mapping[address(this)].supplyAvailable == 0
            ) {
                pre_Sale_2_mapping[address(this)].saleActive = false;
            }
        }

        //  Round cannot be started when another is acticted

        if (
            pre_Sale_1_mapping[address(this)].saleActive ||
            pre_Sale_2_mapping[address(this)].saleActive
        ) {
            revert NotTimeToMint2();
        }

        pre_Sale_3_mapping[address(this)] = Sale_1_tokens(
            30000000000000000,
            block.timestamp,
            endTime,
            10000000000000000000000000,
            0,
            msg.sender,
            true
        );
        currencyinUSDT = pre_Sale_3_mapping[address(this)].price;

        active_3 = true;
        BnbPrice = getLatestPrice(); // BNB price with 8 decimals
        TOKEN_PRICE = (currencyinUSDT * 10**8) / uint256(BnbPrice);
    }

    function startTimee(uint256 _startTime) external  {
        startTime = _startTime;
    }

    function setTime(uint256 presale, uint256 time) public  {
        if (presale == 1) {
            pre_Sale_1_mapping[address(this)].endTime = time;
        } else if (presale == 2) {
            pre_Sale_2_mapping[address(this)].endTime = time;
        } else if (presale == 3) {
            pre_Sale_3_mapping[address(this)].endTime = time;
        } else {
            revert LogicalIssue();
        }
    }

  function buyTokens(uint256 token, currency choice)
        external
        payable
        nonReentrant
    {
        require(remainingToken >= token, "Not enough tokens available");
        _currencyCoice[currency.USDT] = 0;
        _currencyCoice[currency.BNB] = 1;
        numberOfTransactions.increment();
        uint256 pre_Sale_1_tokens;
        uint256 pre_Sale_3_tokens;
        uint256 pre_Sale_2_tokens;

        if (block.timestamp < pre_Sale_1_mapping[address(this)].endTime) {
            if (_currencyCoice[choice] == 0) {
                cost = (token * currencyinUSDT) / 10**18;
            } else if (_currencyCoice[choice] == 1) {
                BnbPrice = getLatestPrice(); // BNB price with 8 decimals

                TOKEN_PRICE = (currencyinUSDT * 10**8) / uint256(BnbPrice);

                emit Token(TOKEN_PRICE);

                // Adjust the multiplication and division to handle decimal places correctly
                cost = (token * TOKEN_PRICE) / 10**18;

                emit bnb(cost);
                require(msg.value >= cost, "Insufficient BNB sent");
                (bool sent, ) = owner().call{value: msg.value}("");
                require(sent, "Failed to send BNB to owner");

            } else {
                revert("Invalid currency choice.");
            }
            pre_Sale_1_mapping[address(this)].supplyAvailable -= token;

            pre_Sale_1_tokens += token;
            userToken_1[msg.sender] += pre_Sale_1_tokens;
        } else if (
            block.timestamp < pre_Sale_2_mapping[address(this)].endTime
        ) {
            if (_currencyCoice[choice] == 0) {
                cost = (token * currencyinUSDT) / 10**18;
            } else if (_currencyCoice[choice] == 1) {
                BnbPrice = getLatestPrice(); // BNB price with 8 decimals

                TOKEN_PRICE = (currencyinUSDT * 10**8) / uint256(BnbPrice);

                emit Token(TOKEN_PRICE);

                // Adjust the multiplication and division to handle decimal places correctly
                cost = (token * TOKEN_PRICE) / 10**18;

                emit bnb(cost);
                require(msg.value >= cost, "Insufficient BNB sent");
                 (bool sent, ) = owner().call{value: msg.value}("");
                require(sent, "Failed to send BNB to owner");

            } else {
                revert("Invalid currency choice.");
            }
            pre_Sale_2_mapping[address(this)].supplyAvailable -= token;
            if (block.timestamp > pre_Sale_2_mapping[address(this)].endTime) {
                pre_Sale_2_mapping[address(this)].saleActive = false;
            }
            pre_Sale_2_tokens += token;
            userToken_2[msg.sender] += pre_Sale_2_tokens;
        } else if (
            block.timestamp < pre_Sale_3_mapping[address(this)].endTime
        ) {
            if (pre_Sale_2_mapping[address(this)].endTime > block.timestamp) {
                revert NotTimeToMint2();
            }

            if (!pre_Sale_3_mapping[address(this)].saleActive) {
                revert NotTimeToMint2();
            }

            if (_currencyCoice[choice] == 0) {
                cost = (token * currencyinUSDT) / 10**18;
            } else if (_currencyCoice[choice] == 1) {
                BnbPrice = getLatestPrice(); // BNB price with 8 decimals

                TOKEN_PRICE = (currencyinUSDT * 10**8) / uint256(BnbPrice);

                emit Token(TOKEN_PRICE);

                // Adjust the multiplication and division to handle decimal places correctly
                cost = (token * TOKEN_PRICE) / 10**18;

                emit bnb(cost);
                require(msg.value >= cost, "Insufficient BNB sent");
                 (bool sent, ) = owner().call{value: msg.value}("");
                require(sent, "Failed to send BNB to owner");

            } else {
                revert("Invalid currency choice.");
            }
            pre_Sale_3_mapping[address(this)].supplyAvailable -= token;
            if (block.timestamp > pre_Sale_3_mapping[address(this)].endTime) {
                pre_Sale_3_mapping[address(this)].saleActive = false;
            }
            pre_Sale_3_tokens += token;
            userToken_3[msg.sender] += pre_Sale_3_tokens;
        } else {
            revert LogicalIssue();
        }

        NumberOfBuying[msg.sender]++;
        uint256 currentTransactionCount = NumberOfBuying[msg.sender];
        userTokens[msg.sender] = userTokens[msg.sender] + token;
        checkTokens[address(this)][msg.sender].amount =
            userToken_1[msg.sender] +
            userToken_2[msg.sender] +
            userToken_3[msg.sender];
        checkTokens[address(this)][msg.sender] = userDetail(
            _currencyCoice[choice] == 0 ? currencyinUSDT : TOKEN_PRICE,
            userTokens[msg.sender],
            block.timestamp,
            userToken_1[msg.sender],
            userToken_2[msg.sender],
            userToken_3[msg.sender],
            msg.sender,
            address(this),
            false,
            0,
            0,
            0
        );
        TokenRecord[msg.sender][currentTransactionCount] = userRecord(
            msg.sender,
            token,
            _currencyCoice[choice] == 0 ? currencyinUSDT : TOKEN_PRICE,
            cost,
            false,
            choice
        );
        if (_currencyCoice[choice] == 0) {
            IERC20(UsdcContract).safeTransferFrom(msg.sender, owner(), cost);
        }

        remainingToken = remainingToken - token;
    }

    function multiTransfer(address[] memory receivers, uint256[] memory amounts)
        public onlyOwner
    {
        require(receivers.length != 0, "Cannot Proccess Null Transaction");
        require(
            receivers.length == amounts.length,
            "Address and Amount array length must be same"
        );
        for (uint256 i = 0; i < receivers.length; i++) {
            IERC20(address(this)).transfer(receivers[i], amounts[i]);
            remainingToken = remainingToken - amounts[i];
        }
    }

    function myClaim() external {
        uint256 token_1;
        uint256 token_2;
        uint256 token_3;
        uint256 tokenPercent;
        require(startTime > 0, "Claiming not started yet");
        require(
            block.timestamp >= startTime,
            "Claiming period has not started"
        );
        require(
            checkTokens[address(this)][msg.sender].user == msg.sender,
            "Not authorized"
        );
        require(
            !checkTokens[address(this)][msg.sender].firstClaim ||
                (block.timestamp - startTime) / seconds_in_month >= cliff,
            "clif period not ended"
        );
        // Ensure the current period is within the valid range (after the cliff and before periods end)
        // require(currentPeriod > cliff, "Cliff period not ended yet");
        // require(currentPeriod <= periods, "Vesting period ended");
        if (checkTokens[address(this)][msg.sender].firstClaim == false) {
            token_1 =
                (checkTokens[address(this)][msg.sender].preSale_1 * 4) /
                100;
            token_2 =
                (checkTokens[address(this)][msg.sender].preSale_2 * 5) /
                100;
            token_3 =
                (checkTokens[address(this)][msg.sender].preSale_3 * 6) /
                100; // 4%
            tokenPercent = token_1 + token_2 + token_3;
            IERC20(address(this)).transfer(msg.sender, tokenPercent); // Transfer 4%
            checkTokens[address(this)][msg.sender].preSale_1 =
                checkTokens[address(this)][msg.sender].preSale_1 -
                token_1;
            checkTokens[address(this)][msg.sender].preSale_2 =
                checkTokens[address(this)][msg.sender].preSale_2 -
                token_2;
            checkTokens[address(this)][msg.sender].preSale_3 =
                checkTokens[address(this)][msg.sender].preSale_3 -
                token_3;
            checkTokens[address(this)][msg.sender].firstClaim = true;
            lastClaimedPeriodForPreSale1[msg.sender] =
                lastClaimedPeriodForPreSale1[msg.sender] +
                1;
            checkTokens[address(this)][msg.sender].first_claimed_at = block
                .timestamp;
        }
        if ((block.timestamp - startTime) / seconds_in_month >= cliff) {
            uint256 current_periods;

            if (checkTokens[address(this)][msg.sender].last_claimed_at == 0) {
                // First claim, calculate based on the initial timestamp
                current_periods =
                    ((block.timestamp - startTime) / seconds_in_month) -
                    cliff;
                require(current_periods > 0, "Cannot claim at the moment");
            } else {
                // Subsequent claim, calculate based on the last claimed timestamp
                current_periods =
                    (block.timestamp -
                        checkTokens[address(this)][msg.sender]
                            .last_claimed_at) /
                    seconds_in_month;
                require(current_periods > 0, "Cannot claim at the moment");
            }

            uint256 total_transferable;
            if (
                current_periods >= total_periods ||
                (current_periods +
                    checkTokens[address(this)][msg.sender].claimed_periods) >
                total_periods
            ) {
                current_periods =
                    total_periods -
                    checkTokens[address(this)][msg.sender].claimed_periods;
                total_transferable =
                    checkTokens[address(this)][msg.sender].preSale_1 +
                    checkTokens[address(this)][msg.sender].preSale_2 +
                    checkTokens[address(this)][msg.sender].preSale_3;
                // Update the user's claimed amounts
                checkTokens[address(this)][msg.sender].preSale_1 = 0;
                checkTokens[address(this)][msg.sender].preSale_2 = 0;
                checkTokens[address(this)][msg.sender].preSale_3 = 0;
            } else {
                // Calculate token amounts based on the current periods
                uint256 presale_1_token = (checkTokens[address(this)][
                    msg.sender
                ].preSale_1 /
                    (total_periods -
                        checkTokens[address(this)][msg.sender]
                            .claimed_periods)) * current_periods;
                uint256 presale_2_token = (checkTokens[address(this)][
                    msg.sender
                ].preSale_2 /
                    (total_periods -
                        checkTokens[address(this)][msg.sender]
                            .claimed_periods)) * current_periods;
                uint256 presale_3_token = (checkTokens[address(this)][
                    msg.sender
                ].preSale_3 /
                    (total_periods -
                        checkTokens[address(this)][msg.sender]
                            .claimed_periods)) * current_periods;
                total_transferable =
                    presale_1_token +
                    presale_2_token +
                    presale_3_token;
                checkTokens[address(this)][msg.sender]
                    .preSale_1 -= presale_1_token;
                checkTokens[address(this)][msg.sender]
                    .preSale_2 -= presale_2_token;
                checkTokens[address(this)][msg.sender]
                    .preSale_3 -= presale_3_token;
            }

            require(total_transferable > 0, "No tokens to transfer");
            IERC20(address(this)).transfer(msg.sender, total_transferable);

            // Update tracking variables
            checkTokens[address(this)][msg.sender]
                .claimed_periods += current_periods;
            checkTokens[address(this)][msg.sender]
                .last_claimed_at = checkTokens[address(this)][msg.sender]
                .last_claimed_at == 0
                ? block.timestamp
                : checkTokens[address(this)][msg.sender].last_claimed_at +
                    (current_periods * seconds_in_month);
        }
    }

    function checkPreSaleActive() public view returns (string memory) {
        string memory presale;
        if (pre_Sale_1_mapping[address(this)].saleActive) {
            presale = "Presale 1 Active";
        } else if (pre_Sale_2_mapping[address(this)].saleActive) {
            presale = "Presale 2 Active";
        } else if (pre_Sale_3_mapping[address(this)].saleActive) {
            presale = "Presale 3 Active";
        } else {
            revert("No Sale Active");
        }

        return presale;
    }

    function getLatestPrice() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,

        ) = priceFeed.latestRoundData();
        return (price);
    }

    function getPrice_W_R_T_BNB(uint256 _bnb) public view returns (uint256) {
        uint256 price;
        uint256 answer;
        if (pre_Sale_1_mapping[address(this)].saleActive) {
            price = TOKEN_PRICE;
        } else if (pre_Sale_2_mapping[address(this)].saleActive) {
            price = TOKEN_PRICE;
        } else if (pre_Sale_3_mapping[address(this)].saleActive) {
            price = TOKEN_PRICE;
        } else {
            revert("No Sale Active");
        }
        answer = (_bnb * 10**18) / price;
        return answer;
    }

    function getPrice_W_R_T_USDT(uint256 _usdt) public view returns (uint256) {
        uint256 price;
        uint256 answer;
        if (pre_Sale_1_mapping[address(this)].saleActive) {
            price = currencyinUSDT;
        } else if (pre_Sale_2_mapping[address(this)].saleActive) {
            price = currencyinUSDT;
        } else if (pre_Sale_3_mapping[address(this)].saleActive) {
            price = currencyinUSDT;
        } else {
            revert("No Sale Active");
        }

        answer = (_usdt * 10**18) / price;
        return answer;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}