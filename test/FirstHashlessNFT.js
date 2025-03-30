const { ethers } = require('hardhat');
const { expect } = require('chai');
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');

const RECEIVER_MAGIC_VALUE = '0x150b7a02';

describe('FirstHashless NFT', function () {
  const fixture = async () => {
    const addressRegistry = await ethers.deployContract("AddressRegistry");
    const firstHashlessNFT = await ethers.deployContract("$FirstHashlessNFT", [addressRegistry.target]);
    const accounts = await ethers.getSigners();
    const [owner, holder1, holder2] = accounts;
    return { addressRegistry, firstHashlessNFT, owner, holder1, holder2 };
  };

  beforeEach(async function () {
    Object.assign(this, await loadFixture(fixture));
  });

  it('default metadata', async function () {
    expect(await this.firstHashlessNFT.symbol()).to.equal("1!#");
    expect(await this.firstHashlessNFT.name()).to.equal("FirstHashlessNFT");
    expect(await this.firstHashlessNFT.$_baseURI()).to.equal("");
  });

  it('set base uri', async function () {
    await this.firstHashlessNFT.setBaseURI("http://example.com/");

    expect(await this.firstHashlessNFT.$_baseURI()).to.equal("http://example.com/");
  });

  it('only owner can set base uri', async function () {
    await expect(this.firstHashlessNFT.connect(this.holder1).setBaseURI("http://example.com/"))
      .to.be.revertedWith("unauthorized");
  });

  it('freeze metadata', async function () {
    await expect(this.firstHashlessNFT.freezeMetadata())
      .to.emit(this.firstHashlessNFT, "MetadataFrozen");
  });
  
  it('cannot freeze metadata twice', async function () {
    await this.firstHashlessNFT.freezeMetadata();
    await expect(this.firstHashlessNFT.freezeMetadata())
      .to.not.emit(this.firstHashlessNFT, "MetadataFrozen");
  });

  it('only owner can freeze metadata', async function () {
    await expect(this.firstHashlessNFT.connect(this.holder1).freezeMetadata())
      .to.be.revertedWith("unauthorized");
  });
  
  it('cannot set base uri when metadata frozen', async function () {
    await this.firstHashlessNFT.freezeMetadata();
    await expect(this.firstHashlessNFT.setBaseURI("http://example.com/"))
      .to.be.revertedWith("metadata frozen");
  });
  
  it('token uri is empty without base uri', async function () {
    await this.firstHashlessNFT.register();
    expect(await this.firstHashlessNFT.tokenURI(1))
      .to.be.equal("");
  });
  
  it('token uri', async function () {
    await this.firstHashlessNFT.register();
    await this.firstHashlessNFT.setBaseURI("http://example.com/");
    expect(await this.firstHashlessNFT.tokenURI(1))
      .to.be.equal("http://example.com/1");
  });
  
  it('token uri with metadata frozen', async function () {
    await this.firstHashlessNFT.setBaseURI("http://example.com/");
    await this.firstHashlessNFT.freezeMetadata();
    await this.firstHashlessNFT.register();
    expect(await this.firstHashlessNFT.tokenURI(1))
      .to.be.equal("http://example.com/1");
  });

  it('registering emits the event', async function () {
    await expect(this.firstHashlessNFT.connect(this.holder1).register())
      .to.emit(this.firstHashlessNFT, "Transfer")
      .withArgs(ethers.ZeroAddress, this.holder1.address, 1);
  });

  it('cannot register twice', async function () {
    await this.firstHashlessNFT.connect(this.holder1).register();
    await expect(this.firstHashlessNFT.connect(this.holder1).register())
      .to.not.emit(this.firstHashlessNFT, "Transfer");
  });

  it('confirm token ownership', async function () {
    await this.firstHashlessNFT.connect(this.holder1).register();
    expect(await this.firstHashlessNFT.ownerOf(1))
      .to.be.eq(this.holder1.address);
  });

  it('confirm address registration', async function () {
    await this.firstHashlessNFT.connect(this.holder1).register();
    expect(await this.addressRegistry.getAddressId(this.holder1.address))
      .to.be.eq(1);
    expect(await this.addressRegistry.findAddressById(1))
      .to.be.eq(this.holder1.address);
  });

  it('get registered address from the token', async function () {
    await this.firstHashlessNFT.connect(this.holder1).register();
    expect(await this.firstHashlessNFT.getRegisteredAddress(1))
      .to.be.eq(this.holder1.address);
  });

  it('cannot get registered address from non existing token', async function () {
    await this.firstHashlessNFT.connect(this.holder1).register();
    await expect(this.firstHashlessNFT.getRegisteredAddress(2))
      .to.be.revertedWithCustomError(this.firstHashlessNFT, 'ERC721NonexistentToken')
      .withArgs(2);
  });

  it('can mint token for already registered address', async function () {
    await this.addressRegistry.addressId(this.holder1.address);
    await expect(this.firstHashlessNFT.connect(this.holder1).register())
      .to.emit(this.firstHashlessNFT, "Transfer")
      .withArgs(ethers.ZeroAddress, this.holder1.address, 1);
  });

  it('a wallet contract can register', async function () {
    const data = '0x42';
    const firstHashlessNFTReceiver = 
      await ethers.deployContract("FirstHashlessNFTReceiver", [RECEIVER_MAGIC_VALUE, this.addressRegistry.target, this.firstHashlessNFT.target]);
    await expect(firstHashlessNFTReceiver.register(data))
      .to.emit(firstHashlessNFTReceiver, 'Received')
      .withArgs(firstHashlessNFTReceiver.target, ethers.ZeroAddress, 1, data);
  });

  it('a non wallet contract cannot register', async function () {
    const data = '0x42';
    const firstHashlessNFTReceiver = 
      await ethers.deployContract("FirstHashlessNFTReceiver", ['0x00000000', this.addressRegistry.target, this.firstHashlessNFT.target]);
    await expect(firstHashlessNFTReceiver.register(data))
      .to.be.revertedWithCustomError(this.firstHashlessNFT, 'ERC721InvalidReceiver')
      .withArgs(firstHashlessNFTReceiver.target);
  });

  it('two registered', async function () {
    await this.firstHashlessNFT.connect(this.holder1).register();
    await this.firstHashlessNFT.connect(this.holder2).register();
    expect(await this.firstHashlessNFT.ownerOf(1))
      .to.be.eq(this.holder1.address);
    expect(await this.firstHashlessNFT.ownerOf(2))
      .to.be.eq(this.holder2.address);
  });

  it('gaps in token ids', async function () {
    await this.addressRegistry.addressId(this.holder1.address);
    await this.firstHashlessNFT.connect(this.holder2).register();
    await expect(this.firstHashlessNFT.ownerOf(1))
      .to.be.revertedWithCustomError(this.firstHashlessNFT, 'ERC721NonexistentToken')
      .withArgs(1);
    expect(await this.firstHashlessNFT.ownerOf(2))
      .to.be.eq(this.holder2.address);
  });

  // this is very long test, may fail due the timeout
  it('10_000 tokens', async function () {
    await this.addressRegistry.addressId(this.holder1.address);
    const firstHashlessNFT_10_000_test = 
      await ethers.deployContract("FirstHashlessNFT_10_000_test", [this.addressRegistry.target, this.firstHashlessNFT.target]);

    for (let i = 0; i < 10_000; i++) {
      await firstHashlessNFT_10_000_test.register();
    }

    await expect(this.firstHashlessNFT.connect(this.holder1).register())
      .to.be.revertedWith('no more tokens');
  }).timeout(200000);

});
