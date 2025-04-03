require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-ignition-ethers");
require('hardhat-exposed');
require("@nomicfoundation/hardhat-verify");

const INFURA_API_KEY = vars.get("INFURA_API_KEY");
const DEPLOYER_PK = vars.get("DEPLOYER_PK");
const ETHERSCAN_API_KEY = vars.get("ETHERSCAN_API_KEY");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    hardhat: {
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [`${DEPLOYER_PK}`],
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [`${DEPLOYER_PK}`],
    },
    'polygon-mainnet': {
      url: `https://polygon-mainnet.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [`${DEPLOYER_PK}`],
    },  
    'base-mainnet': {
      url: `https://base-mainnet.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [`${DEPLOYER_PK}`],
    },
    'optimism-mainnet': {
      url: `https://optimism-mainnet.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [`${DEPLOYER_PK}`],
    },
  },
  solidity:{
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10_000,
      },
    },
  },
  etherscan: {
    apiKey: `${ETHERSCAN_API_KEY}`,
  },
  sourcify: {
    enabled: true,
  }
};
