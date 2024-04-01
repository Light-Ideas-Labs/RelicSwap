require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config({ path: ".env" });

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {

    localhost: {
      url: "http://127.0.0.1:8545",
      accounts: {mnemonic: process.env.DEV_CHAIN_MNEMONIC,},
    },

    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY_SEPOLIA}`,
      accounts: [process.env.WALLET_PRIVATE_KEY],
    },

    ethereum: {
      url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY_MAIN}`,
      accounts: [process.env.WALLET_PRIVATE_KEY],
      chainId: 44787,
    },

    alfajores: {
      url: "https://alfajores-forno.celo-testnet.org",
      accounts: [process.env.WALLET_PRIVATE_KEY],
      chainId: 44787,
    },
    
    celo: {
      url: "https://forno.celo.org",
      accounts: [process.env.WALLET_PRIVATE_KEY],
      chainId: 42220,
    },
  },
  
  // ethereum - celo - explorer API keys
  etherscan: {
    apiKey: {
      // Get it from here: https://celoscan.io/myapikey
      alfajores: process.env.CELOSCAN_API_KEY,
      celo: process.env.CELOSCAN_API_KEY,
    },
  },
  solidity:{
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};
