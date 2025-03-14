// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAddressRegistry {
    error NotFound();
    error InvalidId();
    event AddressId(address indexed addr, uint256 indexed id);
    
    function getAddressId(address addr) external view returns (uint256 id);
    function addressId(address addr) external returns (uint256 id);
    function getAddressById(uint256 id) external view returns (address addr);
}