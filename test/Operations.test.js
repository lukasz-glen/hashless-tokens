const { ethers } = require('hardhat');
const { expect } = require('chai');
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');

describe('Operations', function () {
  const fixture = async () => {
    const operations = await ethers.deployContract("OperationsMock");
    return { operations };
  };

  beforeEach(async function () {
    Object.assign(this, await loadFixture(fixture));
  });

  it('saves null string', async function () {
    const str = "";
    await this.operations.saveString(str, 0xffff);
    expect(await this.operations.loadString(0xffff)).to.equal(str);
  });
  
  it('saves short string', async function () {
    const str = "ABCDE";
    await this.operations.saveString(str, 0xffff);
    expect(await this.operations.loadString(0xffff)).to.equal(str);
  });
  
  it('saves 31 bytes string', async function () {
    const str = "ABCDEFGHIJABCDEFGHIJABCDEFGHIJ1";
    await this.operations.saveString(str, 0xffff);
    expect(await this.operations.loadString(0xffff)).to.equal(str);
  });

  it('saves 32 bytes string', async function () {
    const str = "ABCDEFGHIJABCDEFGHIJABCDEFGHIJ12";
    await this.operations.saveString(str, 0xffff);
    expect(await this.operations.loadString(0xffff)).to.equal(str);
  });

  it('saves long string', async function () {
    const str = "ABCDEFGHIJABCDEFGHIJABCDEFGHIJABCDEFGHIJABCDEFGHIJABCDEFGHIJABCDEFGHIJABCDEFGHIJ";
    await this.operations.saveString(str, 0xffff);
    expect(await this.operations.loadString(0xffff)).to.equal(str);
  });

  it('does not override next string 1', async function () {
    const str1 = "";
    const str2 = "FGHIJ";
    await this.operations.saveString(str2, 0x10000);
    await this.operations.saveString(str1, 0xffff);
    await this.operations.saveString(str2, 0x10000);
    expect(await this.operations.loadString(0xffff)).to.equal(str1);
    expect(await this.operations.loadString(0x10000)).to.equal(str2);
  });

  it('does not override next string 2', async function () {
    const str1 = "ABCDE";
    const str2 = "FGHIJ";
    await this.operations.saveString(str2, 0x10001);
    await this.operations.saveString(str1, 0xffff);
    await this.operations.saveString(str2, 0x10001);
    expect(await this.operations.loadString(0xffff)).to.equal(str1);
    expect(await this.operations.loadString(0x10001)).to.equal(str2);
  });

  it('does not override next string 3', async function () {
    const str1 = "ABCDEFGHIJABCDEFGHIJABCDEFGHIJABCDEFGHIJABCDEFGHIJABCDEFGHIJABCDEFGHIJABCDEFGHIJ";
    const str2 = "FGHIJ";
    await this.operations.saveString(str2, 0x10003);
    await this.operations.saveString(str1, 0xffff);
    await this.operations.saveString(str2, 0x10003);
    expect(await this.operations.loadString(0xffff)).to.equal(str1);
    expect(await this.operations.loadString(0x10003)).to.equal(str2);
  });
});
