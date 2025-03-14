const { ethers } = require('hardhat');
const { expect } = require('chai');
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');

describe('AddressRegistry', function () {
  const fixture = async () => {
    const addressRegistry = await ethers.deployContract("AddressRegistry");
    return { addressRegistry };
  };

  beforeEach(async function () {
    Object.assign(this, await loadFixture(fixture));
  });

  it('saves an address', async function () {
    const addr = "0x1000000000000000000000000000000000000000";
    await this.addressRegistry.addressId(addr);
    expect(await this.addressRegistry.getAddressId(addr)).to.equal(1);
  });

  it('saves an address twice', async function () {
    const addr = "0x1000000000000000000000000000000000000000";
    await this.addressRegistry.addressId(addr);
    await this.addressRegistry.addressId(addr);
    expect(await this.addressRegistry.getAddressId(addr)).to.equal(1);
  });

  it('saves two addresses', async function () {
    const addr1 = "0x1000000000000000000000000000000000000000";
    const addr2 = "0x2000000000000000000000000000000000000000";
    await this.addressRegistry.addressId(addr1);
    await this.addressRegistry.addressId(addr2);
    expect(await this.addressRegistry.getAddressId(addr2)).to.equal(2);
  });

  it('saves zero address', async function () {
    const addr1 = "0x1000000000000000000000000000000000000000";
    const addr2 = "0x0000000000000000000000000000000000000000";
    await this.addressRegistry.addressId(addr1);
    await this.addressRegistry.addressId(addr2);
    expect(await this.addressRegistry.getAddressId(addr2)).to.equal(2);
  });

  it('gets an address by id', async function () {
    const addr1 = "0x1000000000000000000000000000000000000000";
    const addr2 = "0x2000000000000000000000000000000000000000";
    await this.addressRegistry.addressId(addr1);
    await this.addressRegistry.addressId(addr2);
    expect(await this.addressRegistry.getAddressById(1)).to.equal(addr1);
    expect(await this.addressRegistry.getAddressById(2)).to.equal(addr2);
  });

  it('cannot get an address by id zero', async function () {
    const addr1 = "0x1000000000000000000000000000000000000000";
    await this.addressRegistry.addressId(addr1);
    await expect(this.addressRegistry.getAddressById(0))
    .to.be.revertedWithCustomError(this.addressRegistry, 'InvalidId');
  });

  it('cannot get an address by id over limit', async function () {
    const addr1 = "0x1000000000000000000000000000000000000000";
    await this.addressRegistry.addressId(addr1);
    await expect(this.addressRegistry.getAddressById("0x020000000000000000000000000000000000000000"))
    .to.be.revertedWithCustomError(this.addressRegistry, 'InvalidId');
  });

  it('reverts when an address not found', async function () {
    const addr1 = "0x1000000000000000000000000000000000000000";
    const addr2 = "0x2000000000000000000000000000000000000000";
    await this.addressRegistry.addressId(addr1);
    await expect(this.addressRegistry.getAddressId(addr2))
    .to.be.revertedWithCustomError(this.addressRegistry, 'NotFound');
  });

  it('reverts when an id not found', async function () {
    const addr1 = "0x1000000000000000000000000000000000000000";
    await this.addressRegistry.addressId(addr1);
    await expect(this.addressRegistry.getAddressById(2))
    .to.be.revertedWithCustomError(this.addressRegistry, 'NotFound');
  });
});
