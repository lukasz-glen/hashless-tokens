// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Operations} from "../utils/Operations.sol";

abstract contract ERC20MetadataEpsilon {
    bytes32[8] private _name;
    bytes32[8] private _symbol;

    constructor(string memory name_, string memory symbol_) {
        // 1 slot for the string length, 7 slots for string data, 8 in total
        require(bytes(name_).length < (1 << 7) * 32 , "name too long");
        // 1 slot for the string length, 7 slots for string data, 8 in total
        require(bytes(symbol_).length < (1 << 7) * 32, "symbol too long");

        // _name = name_;
        // _symbol = symbol_;
        uint256 nameSlot;
        uint256 symbolSlot;
        assembly {
            nameSlot := _name.slot
            symbolSlot := _symbol.slot
        }
        Operations.saveString(name_, nameSlot);
        Operations.saveString(symbol_, symbolSlot);
    }

    function name() external view returns (string memory) {
        uint256 nameSlot;
        assembly {
            nameSlot := _name.slot
        }
        return Operations.loadString(nameSlot);
    }

    function symbol() external view returns (string memory) {
        uint256 symbolSlot;
        assembly {
            symbolSlot := _symbol.slot
        }
        return Operations.loadString(symbolSlot);
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }
}
