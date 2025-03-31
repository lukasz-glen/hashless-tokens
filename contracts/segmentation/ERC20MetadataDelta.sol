// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Operations} from "../utils/Operations.sol";

abstract contract ERC20MetadataDelta {
    // string private _name;
    // string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        // 1 slot for the string length, 7 slots for string data, 8 in total
        require(bytes(name_).length < (1 << 7) * 32 , "name too long");
        // 1 slot for the string length, 7 slots for string data, 8 in total
        require(bytes(symbol_).length < (1 << 7) * 32, "symbol too long");

        // _name = name_;
        // _symbol = symbol_;
        Operations.saveString(name_, getNameSlot());
        Operations.saveString(symbol_, getSymbolSlot());
    }

    function name() external view returns (string memory) {
        return Operations.loadString(getNameSlot());
    }

    function symbol() external view returns (string memory) {
        return Operations.loadString(getSymbolSlot());
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    ///////////////////// STORAGE LAYOUT FUNCTIONS ////////////////////////////

    /**
     * @custom:segment-length-bits 8
     */
    function getNameSlot() internal virtual pure returns (uint256) {
        return 0;
    }

    /**
     * @custom:segment-length-bits 8
     */
    function getSymbolSlot() internal virtual pure returns (uint256) {
        return 1 << 8;
    }
}
