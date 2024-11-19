require('dotenv').config();
// require('@nomiclabs/hardhat-waffle');
require('@nomiclabs/hardhat-etherscan');

module.exports = {
  solidity: "0.8.24",
  networks: {
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [`0x${process.env.DEPLOYER_PRIVATE_KEY}`]
    }
  },
     
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};