const { ethers } = require('hardhat');
const { expect } = require('chai');

function runERC20Benchmark(initialSupply) {
  beforeEach(async function () {
    [this.holder, this.recipient, this.other] = this.accounts;
  });

  it('benchmark: transfer', async function () {
    const tx = await this.token.connect(this.holder).transfer(this.recipient, 1);
    const receipt = await tx.wait();
    console.log('Gas cost of a transfer to an empty account: ' + receipt.gasUsed);
  });

  it('benchmark: approve (1)', async function () {
    const tx = await this.token.connect(this.holder).approve(this.other, 1);
    const receipt = await tx.wait();
    console.log('Gas cost of an approval to an untouched account: ' + receipt.gasUsed);
  });

  it('benchmark: approve (2)', async function () {
    await this.token.connect(this.holder).approve(this.other, 1);
    const tx = await this.token.connect(this.holder).approve(this.other, initialSupply);
    const receipt = await tx.wait();
    console.log('Gas cost of an approval to a touched account: ' + receipt.gasUsed);
  });

  it('benchmark: transferFrom', async function () {
    await this.token.connect(this.holder).approve(this.other, initialSupply);
    const tx = await this.token.connect(this.other).transferFrom(this.holder, this.recipient, 1);
    const receipt = await tx.wait();
    console.log('Gas cost of a transferFrom to an empty account: ' + receipt.gasUsed);
  });
};

module.exports = {
    runERC20Benchmark,
  };
  