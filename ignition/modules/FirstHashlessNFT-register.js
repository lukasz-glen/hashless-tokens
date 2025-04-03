const { buildModule } = require('@nomicfoundation/hardhat-ignition/modules');
const firstHashlessNFTModule = require('./FirstHashlessNFT');

const firstHashlessNFTModule_register = buildModule("FirstHashlessNFT_register", (m) => {
  const { addressRegistry, firstHashlessNFT } = m.useModule(firstHashlessNFTModule);

  m.call(firstHashlessNFT, "register()", []);

  return { addressRegistry, firstHashlessNFT };
});

module.exports = firstHashlessNFTModule_register;
