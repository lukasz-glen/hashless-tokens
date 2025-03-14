// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20Alpha} from "../segmentation/ERC20Alpha.sol";
import {ERC20Metadata} from "../segmentation/ERC20Metadata.sol";

contract ERC20AlphaMock is ERC20Alpha, ERC20Metadata {
    constructor(string memory name_, string memory symbol_) 
    ERC20Alpha(0x0) 
    ERC20Metadata(1 << 210, name_, symbol_) { }
}
