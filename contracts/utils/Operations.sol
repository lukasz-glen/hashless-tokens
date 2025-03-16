// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Operations {
    function saveString(string memory str, uint256 slot_) internal {
        assembly {
            let len := mload(str)
            switch len
            case 0 {
                sstore(slot_, 0x0)
            }
            default {
                switch lt(len, 0x20) 
                case 0 {
                    sstore(slot_, add(shl(0x1, len), 0x1))
                    let str_ptr := 0x20
                    let p := 0x1
                    for {  } lt(str_ptr ,len) {  } {
                        sstore(add(slot_, p), mload(add(str, str_ptr)))
                        str_ptr := add(str_ptr, 0x20)
                        p := add(p, 0x1)
                    }
                    let str_data := mload(add(str, str_ptr))
                    // just in case, clear trailing data in memory
                    str_data := and(str_data, shl(shl(3, sub(str_ptr, len)), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff))
                    sstore(add(slot_, p), str_data)
                }
                default {
                    let str_data := mload(add(str, 0x20))
                    // just in case, clear trailing data in memory
                    str_data := and(str_data, shl(shl(3, sub(0x20, len)), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff))
                    sstore(slot_, or(str_data, shl(0x1, len)))
                }
            }
        }
    }

    function  loadString(uint256 slot_) internal view returns (string memory str) {
        assembly {
            let first := sload(slot_)
            switch and(0x1, first)
            case 0 {
                str := mload(0x40)
                // Note that Solidity generated IR code reserves memory offset ``0x60`` as well, but a pure Yul object is free to use memory as it chooses.
                if iszero(str) {
                    str := 0x60
                }
                mstore(0x40, add(str, 0x40))

                let len := shr(1, and(first, 0xff))
                mstore(str, len)
                // additionally clear trailing data in storage
                mstore(add(str, 0x20), and(first, shl(shl(3, sub(0x20, len)), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))
            }
            default {
                let len := shr(1, first)
                let words := shr(0x5, add(len, 0x1f))

                str := mload(0x40)
                // Note that Solidity generated IR code reserves memory offset ``0x60`` as well, but a pure Yul object is free to use memory as it chooses.
                if iszero(str) {
                    str := 0x60
                }
                mstore(0x40, add(add(str, 0x20), shl(0x5, words)))

                mstore(str, len)
                for { let i := 0x1 } lt(i, words) { i := add(i, 0x1) } {
                    mstore(add(str, shl(0x5, i)), sload(add(slot_, i)))
                }
                // additionally clear trailing data in storage
                mstore(add(str, shl(0x5, words)), and(sload(add(slot_, words)), shl(sub(shl(0x8, words), shl(0x3, len)), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)))
            }
        }
    }
}