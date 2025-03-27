const { ethers } = require('hardhat');
const { expect } = require('chai');
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');

const name = 'Non Fungible Token';
const symbol = 'NFT';

const baseURI = "https://example.com/";
const firstTokenId = 5042n;
const secondTokenId = 1461501637330902918203684832716283019655932542975n; // 2**160 - 1
const nonExistentTokenId = 13n;
const fourthTokenId = 4n;

async function fixture() {
  return {
    accounts: await ethers.getSigners(),
    token: await ethers.deployContract('$ERC721DeltaMock', [name, symbol]),
  };
}

describe('ERC721 Token Uri', function () {
  beforeEach(async function () {
    Object.assign(this, await loadFixture(fixture));
  });

  it('not empty Token URI', async function () {
    await this.token.$_setBaseURI(baseURI)

    await this.token.$_mint(this.accounts[0], firstTokenId);
    await this.token.$_mint(this.accounts[0], secondTokenId);
    await this.token.$_mint(this.accounts[0], fourthTokenId);

    expect(await this.token.tokenURI(firstTokenId))
      .to.be.equal(baseURI + firstTokenId);
    expect(await this.token.tokenURI(secondTokenId))
      .to.be.equal(baseURI + secondTokenId);
    await expect(this.token.tokenURI(nonExistentTokenId))
      .to.be.revertedWithCustomError(this.token, 'ERC721NonexistentToken')
      .withArgs(nonExistentTokenId);
    expect(await this.token.tokenURI(fourthTokenId))
      .to.be.equal(baseURI + fourthTokenId);
  });
});
