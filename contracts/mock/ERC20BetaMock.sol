// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20Beta} from "../segmentation/ERC20Beta.sol";
import {ERC20Metadata} from "../segmentation/ERC20Metadata.sol";
import {AddressRegistry} from "../utils/AddressRegistry.sol";

contract ERC20BetaMock is ERC20Beta, ERC20Metadata {
    constructor(string memory name_, string memory symbol_) 
    ERC20Beta(0x0, new AddressRegistry()) 
    ERC20Metadata(1 << ERC20Beta.LEVEL_SEGMENT_LENGTH, name_, symbol_) { }
}
