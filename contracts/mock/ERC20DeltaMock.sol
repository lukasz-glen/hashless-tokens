// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20Delta} from "../segmentation/ERC20Delta.sol";
import {ERC20MetadataDelta} from "../segmentation/ERC20MetadataDelta.sol";
import {AddressRegistry} from "../utils/AddressRegistry.sol";

contract ERC20DeltaMock is ERC20Delta, ERC20MetadataDelta {
    constructor(string memory name_, string memory symbol_) 
    ERC20Delta(new AddressRegistry()) 
    ERC20MetadataDelta(name_, symbol_) { }

    /**
     * @custom:segment-length-bits 8
     */
    function getNameSlot() internal virtual override pure returns (uint256) {
        return 1 << 8;
    }

    /**
     * @custom:segment-length-bits 8
     */
    function getSymbolSlot() internal virtual override pure returns (uint256) {
        return 2 << 8;
    }
}
