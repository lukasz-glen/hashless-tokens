const { buildModule } = require('@nomicfoundation/hardhat-ignition/modules');
const addressRegistryModule = require('./AddressRegistry');

const firstHashlessNFTModule = buildModule("FirstHashlessNFT", (m) => {
  const { addressRegistry } = m.useModule(addressRegistryModule);

  const firstHashlessNFT = m.contract("FirstHashlessNFT", [ addressRegistry ]);
  return { addressRegistry, firstHashlessNFT };
});

module.exports = firstHashlessNFTModule;
