// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC721Delta} from "../segmentation/ERC721Delta.sol";
import {AddressRegistry} from "../utils/AddressRegistry.sol";
import {Operations} from "../utils/Operations.sol";

contract ERC721DeltaMock is ERC721Delta {
    constructor(string memory name_, string memory symbol_) 
    ERC721Delta(name_, symbol_, new AddressRegistry()) { }

    function _baseURI() internal view override returns (string memory) {
        return Operations.loadString(getBaseURISlot());
    }

    function _setBaseURI(string memory _newBaseURI) internal {
        require(bytes(_newBaseURI).length < (1 << 8) * 32 , "baseURI too long");
        Operations.saveString(_newBaseURI, getBaseURISlot());
    }
    /**
     * @custom:segment-length-bits 8
     */

    ///////////////////// STORAGE LAYOUT FUNCTIONS ////////////////////////////

    function getBaseURISlot() internal virtual pure returns (uint256) {
        return 3 << 8;
    }

}
