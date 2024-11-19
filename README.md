**SavorVesting Contract📜**

Welcome to the SavorVesting smart contract! This contract is designed to handle token distribution, presale events, and claiming mechanisms for users participating in token sales. Below is a detailed explanation of the contract's features and functions. Let's dive in! 🚀

---

### Contract Overview 💡

The **SavorVesting** contract allows the vesting of tokens for users, facilitates multiple presale rounds, and provides a mechanism for users to buy tokens in exchange for either **USDT** (Tether) or **BNB** (Binance Coin). 

This contract also includes a **cliff** period and **vesting** schedule, which ensures users can claim tokens only after certain conditions are met, ensuring a fair distribution of tokens over time.

---

### Key Features ✨

1. **ERC-20 Token Implementation** 🪙:
   - The contract is built on the **ERC-20** standard, which means the tokens are compatible with most wallets and exchanges.
   - It allows for token minting, burning, and transferring functionalities.

2. **Presale Rounds** 💰:
   - There are **3 presale rounds** (PreSale 1, PreSale 2, and PreSale 3). These rounds determine the price and availability of tokens during different stages of the sale.
   - Tokens can be bought using **USDT** or **BNB**.

3. **Cliff and Vesting Period** ⏳:
   - Users can only claim their tokens after a **cliff** period (3 months). After the cliff, users can claim tokens periodically based on the vesting schedule.
   - The vesting schedule is set for **18 months** in total, with tokens being released progressively.

4. **Claim Mechanism** 🎉:
   - Once the cliff period ends, users can claim their tokens at regular intervals, as defined in the vesting schedule.

---

### Contract Structure 🏗️

#### 1. **Variables** 📊:
   - **IsClaim**: A flag indicating whether users can claim tokens.
   - **AddminAddress**: Admin address for the contract.
   - **USDT**: The address of the USDT contract used for payments.
   - **UsdcContract**: The address of the USDC contract.
   - **remainingToken**: The total number of tokens remaining for distribution.
   - **total_periods**: Total duration of the vesting period (18 months).
   - **cliff**: The cliff period (3 months) before users can start claiming.
   - **currencyinUSDT**: Price of the token in USDT.
   - **TOKEN_PRICE**: The price of the token, which changes depending on the currency used for payment (USDT or BNB).
   - **BnbPrice**: Current price of BNB fetched from the Chainlink price feed.

#### 2. **User Structures** 👥:
   - **userRecord**: Contains details of each user's purchase, including the amount, currency used, and whether the tokens are claimed.
   - **userDetail**: Contains detailed information about a user's vesting, including their purchased amount, last claim time, and the amount they have claimed so far.
   - **Sale_1_tokens**: Contains information about each presale, such as start and end times, token supply, and sale status.

#### 3. **Presale Rounds** 🎯:
   - **PreSale 1**: Initial presale with a specific price and token supply.
   - **PreSale 2**: Second presale with updated prices and token availability.
   - **PreSale 3**: Third presale, typically with the highest prices and limited tokens remaining.

---

### Functions 📜

#### 1. **Admin Functions** 🔧:
   - **AdminAddToken**: Allows the owner to add more tokens to the contract.
   - **transferTokens**: Allows the owner to transfer tokens to a specified address.
   - **multiTransfer**: Allows the owner to distribute tokens to multiple addresses in a single transaction.

#### 2. **Presale Functions** 🛒:
   - **preSale_1_Listing**: Starts **PreSale 1** and sets its price, end time, and token availability.
   - **preSale_2_Listing**: Starts **PreSale 2** with similar parameters to PreSale 1.
   - **preSale_3_Listing**: Starts **PreSale 3** and sets its parameters.
   - **setTime**: Allows the owner to update the end time for a particular presale.

#### 3. **Buy Tokens** 💵:
   - **buyTokens**: Allows users to buy tokens during the presale rounds. Users can pay using either **USDT** or **BNB**. The price of the token is calculated based on the current presale round and the payment currency.

#### 4. **Claim Tokens** 🏆:
   - **myClaim**: Allows users to claim their tokens after the vesting cliff period has ended. The contract ensures that users can only claim tokens periodically, based on the vesting schedule.

#### 5. **Helper Functions** 🔍:
   - **checkPreSaleActive**: Returns the status of the active presale round (1, 2, or 3).
   - **getLatestPrice**: Fetches the current price of **BNB** using the Chainlink price feed.
   - **getPrice_W_R_T_BNB**: Calculates the price of a certain number of **BNB** in terms of the token.
   - **getPrice_W_R_T_USDT**: Calculates the price of a certain amount of **USDT** in terms of the token.

#### 6. **Pause & Unpause** ⏸️:
   - **pause**: Pauses the contract, preventing any transactions.
   - **unpause**: Resumes the contract, allowing transactions to proceed.

---

### Error Handling ⚠️

- **InsufficientTokensAvailable**: Raised when there are not enough tokens available for a transaction.
- **NotTimeToMint2**: Raised when the user tries to buy tokens outside the allowed presale time window.
- **LogicalIssue**: Raised in case of any logical inconsistency in the presale or claim process.
- **NotTimeToMint3**: Raised when the user tries to buy tokens in the wrong presale stage.
- **Sale1Active**: Raised when **PreSale 1** is active but another presale is attempted.
- **Sale2NotActive**: Raised when **PreSale 2** is not active and a user tries to buy tokens during this period.

---

### How It Works 🔄

1. **Buying Tokens**: 
   - Users can buy tokens by sending **USDT** or **BNB** to the contract. The number of tokens they receive depends on the presale stage and the current token price.
   
2. **Vesting and Claiming**:
   - Users need to wait for the **cliff period** (3 months) before claiming any tokens.
   - After the cliff, they can claim tokens based on the vesting schedule, which distributes tokens over the next 18 months.
   
3. **Presale Events**:
   - The contract owner manages presale rounds. Each presale has a specific price and token availability. The presale rounds are sequential, meaning each round can only start after the previous one is either over or fully sold out.

---

### Additional Notes 📝

- The contract ensures that users can only claim tokens after the **cliff** period and in accordance with the **vesting schedule**.
- The contract uses Chainlink to fetch the latest **BNB** price for accurate calculations.
- The contract owner has full control over the presale listing and can add more tokens to the contract if needed.

---

### Conclusion 🎉

The **SavorVesting** contract is a comprehensive solution for managing presales, token purchases, and vesting schedules. It ensures a fair and orderly distribution of tokens over time and provides flexibility for both the contract owner and users participating in the token sale. 💼