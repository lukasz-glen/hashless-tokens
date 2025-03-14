require("@nomicfoundation/hardhat-toolbox");
require('hardhat-exposed');

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  settings: {
    optimizer: {
      enabled: true,
      runs: 10_000,
    },
  },
};
