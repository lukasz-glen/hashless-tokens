const { buildModule } = require('@nomicfoundation/hardhat-ignition/modules');

const addressRegistryModule = buildModule("AddressRegistry", (m) => {
  const addressRegistry = m.contract("AddressRegistry", []);
  return { addressRegistry };
});

module.exports = addressRegistryModule;
