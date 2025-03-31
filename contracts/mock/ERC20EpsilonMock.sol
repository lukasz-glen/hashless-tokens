// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20Epsilon} from "../segmentation/ERC20Epsilon.sol";
import {ERC20MetadataEpsilon} from "../segmentation/ERC20MetadataEpsilon.sol";
import {AddressRegistry} from "../utils/AddressRegistry.sol";

contract ERC20EpsilonMock is ERC20Epsilon, ERC20MetadataEpsilon {
    constructor(string memory name_, string memory symbol_) 
    ERC20Epsilon(new AddressRegistry()) 
    ERC20MetadataEpsilon(name_, symbol_) { }
}
