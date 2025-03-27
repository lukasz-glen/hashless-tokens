const { ethers } = require('hardhat');
const { expect } = require('chai');
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');


describe('AddressRegistry NFT', function () {
  const fixture = async () => {
    const addressRegistry = await ethers.deployContract("AddressRegistry");
    const addressRegistryNFT = await ethers.deployContract("$AddressRegistryNFT", [addressRegistry.target]);
    const accounts = await ethers.getSigners();
    const [owner, holder1, holder2] = accounts;
    return { addressRegistry, addressRegistryNFT, owner, holder1, holder2 };
  };

  beforeEach(async function () {
    Object.assign(this, await loadFixture(fixture));
  });

  it('default metadata', async function () {
    expect(await this.addressRegistryNFT.symbol()).to.equal("AddrReg");
    expect(await this.addressRegistryNFT.name()).to.equal("AddressRegistryNFT");
    expect(await this.addressRegistryNFT.$_baseURI()).to.equal("");
  });

  it('set base uri', async function () {
    await this.addressRegistryNFT.setBaseURI("http://example.com/");

    expect(await this.addressRegistryNFT.$_baseURI()).to.equal("http://example.com/");
  });

  it('only owner can set base uri', async function () {
    await expect(this.addressRegistryNFT.connect(this.holder1).setBaseURI("http://example.com/"))
      .to.be.revertedWith("unauthorized");
  });

  it('freeze metadata', async function () {
    await expect(this.addressRegistryNFT.freezeMetadata())
      .to.emit(this.addressRegistryNFT, "MetadataFrozen");
  });
  
  it('cannot freeze metadata twice', async function () {
    await this.addressRegistryNFT.freezeMetadata();
    await expect(this.addressRegistryNFT.freezeMetadata())
      .to.not.emit(this.addressRegistryNFT, "MetadataFrozen");
  });

  it('only owner can freeze metadata', async function () {
    await expect(this.addressRegistryNFT.connect(this.holder1).freezeMetadata())
      .to.be.revertedWith("unauthorized");
  });
  
  it('cannot set base uri when metadata frozen', async function () {
    await this.addressRegistryNFT.freezeMetadata();
    await expect(this.addressRegistryNFT.setBaseURI("http://example.com/"))
      .to.be.revertedWith("metadata frozen");
  });
  
  it('token uri is empty without base uri', async function () {
    await this.addressRegistryNFT.register();
    expect(await this.addressRegistryNFT.tokenURI(1))
      .to.be.equal("");
  });
  
  it('token uri', async function () {
    await this.addressRegistryNFT.register();
    await this.addressRegistryNFT.setBaseURI("http://example.com/");
    expect(await this.addressRegistryNFT.tokenURI(1))
      .to.be.equal("http://example.com/1");
  });
  
  it('token uri with metadata frozen', async function () {
    await this.addressRegistryNFT.setBaseURI("http://example.com/");
    await this.addressRegistryNFT.freezeMetadata();
    await this.addressRegistryNFT.register();
    expect(await this.addressRegistryNFT.tokenURI(1))
      .to.be.equal("http://example.com/1");
  });
});
