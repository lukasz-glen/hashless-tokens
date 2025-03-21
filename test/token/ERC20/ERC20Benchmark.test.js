const { ethers } = require('hardhat');
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');

const {
  runERC20Benchmark,
} = require('./ERC20.benchmark');

const TOKENS = [{ Token: '$ERC20Mock' }, { Token: '$ERC20AlphaMock' }, { Token: '$ERC20BetaMock' }, { Token: '$ERC20GammaMock' }];

const name = 'My Token';
const symbol = 'MTKN';
const initialSupply = 100n;

describe('ERC20 Gas Usage Benchmarks', function () {
  for (const { Token, forcedApproval } of TOKENS) {
    describe(Token, function () {
      const fixture = async () => {
        // this.accounts is used by shouldBehaveLikeERC20
        const accounts = await ethers.getSigners();
        const [holder, recipient] = accounts;

        const token = await ethers.deployContract(Token, [name, symbol]);
        await token.$_mint(holder, initialSupply);

        return { accounts, holder, recipient, token };
      };

      beforeEach(async function () {
        Object.assign(this, await loadFixture(fixture));
      });

      runERC20Benchmark(initialSupply);
    });
  }
});
