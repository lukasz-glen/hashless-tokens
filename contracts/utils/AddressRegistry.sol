// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IAddressRegistry} from "./IAddressRegistry.sol";

/**
 * @title AddressRegistry
 * @author @lukasz-glen
 * @notice The contract to register addresses.
 * Each address gets an id.
 * Ids are sequential and positive.
 * @dev Any address can register any address.
 * Including zero address.
 * An address gets a unique id, no repeats.
 * The point is that it can be assumed
 * that ids have significantly lower values than addresses.
 * For instance, to exceed 48 bits,
 * almost a quadrillion of addresses have to be registered.
 */
contract AddressRegistry is IAddressRegistry {
    // the storage layout
    // mapping(address => uint256) private addressIds; // registered addresses, 0x segment
    // mapping(uint256 => address) private addresses; // addressId => address, 1<<160 segment
    // uint256 private seq; // last address id, 3<<160 segment

    uint256 private constant addressesSegment = 1 << 160;
    uint256 private constant seqSlot = 3 << 160;

    /**
     * @notice checks if an address was registered
     * @dev returns non zero id or reverts with NotFound if not found
     * @param addr any address, zero address is valid
     * @return id non zero address id if found
     */
    function getAddressId(address addr) external view returns (uint256 id) {
        assembly {
            id := sload(addr)
            if iszero(id) {
                // revert NotFound()
                let free_mem_ptr := mload(64)
                mstore(free_mem_ptr, 0xc5723b5100000000000000000000000000000000000000000000000000000000)
                revert(free_mem_ptr, 4)                
            }
        }
    }

    /**
     * @notice registers an address
     * @dev if an address is already registered,
     * the existing address id is returned
     * @param addr any address, zero address is valid
     * @return id non zero address id
     */
    function addressId(address addr) external returns (uint256 id) {
        assembly {
            id := sload(addr)
        }
        if (id == 0) {
            assembly {
                id := add(sload(seqSlot), 1)
                sstore(seqSlot, id)
                sstore(addr, id)
                // 1 is set at 161 bit to support zero address
                sstore(add(addressesSegment, id), or(addr, 0x010000000000000000000000000000000000000000))
            }
            emit AddressId(addr, id);
        }
    }

    /**
     * @notice looks up an address by address id
     * @dev reverts with NotFound if not found,
     * in theory the address id is limited by 1 << 160
     * @param id on zero address id
     * @return addr non zero address id if found
     */
    function getAddressById(uint256 id) external view returns (address addr) {
        if (id == 0 || id > 0x010000000000000000000000000000000000000000) {
            revert InvalidId();
        }
        assembly {
            addr := sload(add(addressesSegment, id))
            if iszero(addr) {
                // revert NotFound()
                let free_mem_ptr := mload(64)
                mstore(free_mem_ptr, 0xc5723b5100000000000000000000000000000000000000000000000000000000)
                revert(free_mem_ptr, 4)                
            }
            // 1 is set at 161 bit to support zero address
            addr := and(addr, 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }
}
