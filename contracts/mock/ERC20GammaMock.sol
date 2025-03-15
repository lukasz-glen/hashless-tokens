// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20Gamma} from "../segmentation/ERC20Gamma.sol";
import {ERC20Metadata} from "../segmentation/ERC20Metadata.sol";

contract ERC20GammaMock is ERC20Gamma, ERC20Metadata {
    constructor(string memory name_, string memory symbol_) 
    ERC20Gamma(0x0) 
    ERC20Metadata(1 << ERC20Gamma.LEVEL_SEGMENT_LENGTH, name_, symbol_) { }
}
