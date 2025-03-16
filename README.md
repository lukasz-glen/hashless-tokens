# HashLess Tokens

Several implementations of statndard tokens, ERC20, ERC721, NFT1155, 
with a special purpose - to not use `keccak256`.

## Hashing

Hashing operations turned out to be a problem when generating ZK proofs for a block.
This refers to precompiles like `SHA2-256` and the `KECCAK2556` opcode.
See EIP-7667.

Whenever you use `mapping` type in a solidity smartcontract,
there are `keccak256` executions under the hood.

Here are solidity smartcontracts implementing the standards 
that are not using `mapping` types and `KECCAK256` explicitly.

Note that EVM address is a result of hashing itself,
but outside of a contract.

Note that it is not possible to eliminate using `keccak256`.
For instance, see EIP-712.

## Segments

32 bytes for key length is a lot.
Smartcontracts and using even a fraction of it,
and they are not indended to.

Standard solidity shares storage.
If a contract has two `mapping` variables,
they both are using the whole storage.
Probability of collision is astronomical.

Here is proposed an alternative approach.
Each variable gets its own separate storage space.
It is straightforward for a simple variable like
`uint256 public totalSupply`,
it is enough to reserve a single slot.
To replace `mapping(address => uint256) internal balances`
more space is needed, a segment actually.
`2**160` slots is needed to be reserved, 
for instance the segment could consists of slots 
from `1<<160` to `1<<160 + 1<<160 - 1` inclusive.

So far so good.
The challenge is to replace `mapping(address => mapping(address => uint256)) internal approvals`
as `address x address` key requires 320 bits.

The `n` bits segment is a compact space of slots
from `d<<n` to `d<<n + 1<<n - 1` inclusive,
where `d` is some `256-n` bits value.
You can say that `d<<n` is a selector or a discriminator
of segment.

So the goal is to provide a storage layout
by dividing storage into separate segments
assigned to contract's variables,
variables includes lists and mappings.

## Drawbacks

The benefit is obvious: no `keccak256` in contracts.

At the moment the cost is very high.

1. Storage layout is a manual work.
A lot of good things that come with solidity cannot be used.
This impact not only development efficiency
but also security.
2. There is a lot of YUL.
It is harder to use code analyzers and other automated tools
supporting audits.
3. Clasic solidity storage layout (using `mapping`) should not be mixed
with segmented storage layout.
Or at least should be taken with great caution.
For instance, a contract in pure solidity and a contract with segements
should not inherit one from the other. Why?
`mapping` covers the whole storage. 
With a segment, a raw user's input may be used to calculate a storage slot.
It may be much easier to find a collistion.

There is a hope that the situation will get better in time.
Technically it is quite possible.

## Level segment

Not only variables need segments.
Contracts in an inheritance tree must use different storage space,
segments cannot overlap.
So each contract in the inheritance tree, i.e. level,
defines the level segment.
It defines the length in bits, but does not define the selector/discriminator.
The latter is a constructor parameter.
The top level contract should define selectors/discriminators for
all inherited contracts, actually defines the storage layout.
The level segment is further divided into segments according to variables
defined by a contract.

## Implementations

1. Alpha. Internally, 160 bits length spender address is mapped to 48 bits length id. 
2. Beta. Externally, 160 bits length spender address is mapped to 48 bits length id.
Externally with Address Registry Contract.
3. Gamma. To support allowances in storage, the spender address is cut to 90 high bits.

## Address Registry Contract

As stated above,
the challenge is to replace `mapping(address => mapping(address => uint256)) internal approvals`
as `address x address` key requires 320 bits.

`keccak256` is the source of random access to storage.
The idea is to replace values based on `keccak256` with
those with shorter ranges. Note that the address is
the result of `keccak256` also. But it cannot be replaced directly.

The number of address that will be ever in use is limited,
both by cryptographic design and blockchain capabilities.
No more than `2**48` addresses ever is a rough estimate.

The soft solution, contract level, is Address Registry Contract.
You or any contract can register any address
and a sequential number is assigned.
This way 160 bit long address is replaced with 48 bit long id.
And `address x address` key is reduced to 96 bits.

Please note that Address Registry Contract 
is not used in every token implementation.
This is one of possible solutions.
The point is that it can be shared by multiple tokens
saving code, gas and storage.

## Tests

Token tests are borrowed from OpenZeppelin, MIT license. 
Actually, this impacted the implementation design.

## Useful commands

Install dependencies
```shell
npm ci
```

May need `--force` to trigger hardhat-exposed
```shell
npx hardhat compile --force
```

Obvious
```shell
npx hardhat test
```
