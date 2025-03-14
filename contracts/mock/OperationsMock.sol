// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Operations} from "../utils/Operations.sol";

contract OperationsMock {
    function saveString(string memory str, uint256 slot_) external {
        Operations.saveString(str, slot_);
    }

    function  loadString(uint256 slot_) external view returns (string memory str) {
        return Operations.loadString(slot_);
    }
}