// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Operations} from "../utils/Operations.sol";

abstract contract ERC20Metadata {
    uint256 private immutable level_segment;  // 8 bits length
    // string private _name;
    // string private _symbol;

    constructor(uint256 _level_segment, string memory name_, string memory symbol_) {
        require(
            _level_segment & 0xff == 0,
            "invalid level segment selector"
            );
        level_segment = _level_segment;

        require(bytes(name_).length < 1024, "name too long");
        require(bytes(symbol_).length < 32, "symbol too long");

        // _name = name_;
        // _symbol = symbol_;
        Operations.saveString(name_, _level_segment);
        Operations.saveString(symbol_, _level_segment + 0x7f);
    }

    function name() external view returns (string memory) {
        return Operations.loadString(level_segment);
    }

    function symbol() external view returns (string memory) {
        return Operations.loadString(level_segment + 0x7f);
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }
}
