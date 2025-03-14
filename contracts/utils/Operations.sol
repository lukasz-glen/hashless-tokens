// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Operations {
    function saveString(string memory str, uint256 slot_) internal {
        assembly {
            let len := mload(str)
            if iszero(len) {
                sstore(slot_, 0x0)
            }
            if iszero(iszero(len)) {
                // TODO clear trailing trash
                if lt(len, 0x20) {
                    sstore(slot_, or(mload(add(str, 0x20)), shl(0x1, len)))
                }
                if gt(len, 0x1f) {
                    sstore(slot_, add(shl(0x1, len), 0x1))
                    let str_data := 0x0
                    for { let p := 0x1 } iszero(gt(str_data ,len)) { p := add(p, 0x1) } {
                        sstore(add(slot_, p), mload(add(add(str, str_data), 0x20)))
                        str_data := add(str_data, 0x20)
                    }
                }
            }
        }
    }

    function  loadString(uint256 slot_) internal view returns (string memory str) {
        assembly {
            let first := sload(slot_)
            // TODO clear trailing trash
            if iszero(and(0x1, first)) {
                str := mload(0x40)
                // Note that Solidity generated IR code reserves memory offset ``0x60`` as well, but a pure Yul object is free to use memory as it chooses.
                if iszero(str) {
                    str := 0x60
                }
                mstore(0x40, add(str, 0x40))

                mstore(str, shr(1, and(first, 0xff)))
                mstore(add(str, 0x20), and(first, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00))
            }
            if iszero(iszero(and(0x1, first))) {
                let len := shr(1, first)
                let words := shr(0x5, add(len, 0x1f))

                str := mload(0x40)
                // Note that Solidity generated IR code reserves memory offset ``0x60`` as well, but a pure Yul object is free to use memory as it chooses.
                if iszero(str) {
                    str := 0x60
                }
                mstore(0x40, add(add(str, 0x20), shl(0x5, words)))

                mstore(str, len)
                for { let i := 0x1 } iszero(gt(i, words)) { i := add(i, 0x1) } {
                    mstore(add(str, shl(0x5, i)), sload(add(slot_, i)))
                }
            }
        }
    }
}