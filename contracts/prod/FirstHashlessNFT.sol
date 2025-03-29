// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {ERC721Delta} from "../segmentation/ERC721Delta.sol";
import {IAddressRegistry} from "../utils/IAddressRegistry.sol";
import {Operations} from "../utils/Operations.sol";

contract FirstHashlessNFT is ERC721Delta {
    event MetadataFrozen();

    // uint256 internal totalSupply;

    address internal immutable contractOwner;

    constructor(IAddressRegistry _addressRegistry) 
    ERC721Delta("FirstHashlessNFT", "1!#", _addressRegistry) {
        contractOwner = msg.sender;
    }

    function register() external {
        register("");
    }

    function register(bytes memory data) public {
        uint256 _totalSupplySlot = getTotalSupplySlot();
        uint256 _totalSupply;
        assembly {
            _totalSupply := sload(_totalSupplySlot)
        }
        require(_totalSupply < 10_000, "no more tokens");

        uint256 addressId = addressRegistry.addressId(msg.sender);

        require (addressId < 2**160, "abnormal");
        uint256 _ownerSlot = getOwnerSlot(uint160(addressId));
        address _owner;
        assembly {
            _owner := sload(_ownerSlot)
        }
        if (_owner != address(0)) {
            return;
        }

        _safeMint(msg.sender, addressId, data);
    }

    function getRegisteredAddress(uint256 tokenId) external view returns(address _registeredAddress) {
        if (tokenId > 2**160 - 1) {
            revert ERC721NonexistentToken(tokenId);
        }
        uint256 _ownerSlot = getOwnerSlot(uint160(tokenId));
        address _owner;
        assembly {
            _owner := sload(_ownerSlot)
        }
        if (_owner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }

        return addressRegistry.findAddressById(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return Operations.loadString(getBaseURISlot());
    }

    function setBaseURI(string memory _newBaseURI) external {
        require(msg.sender == contractOwner, "unauthorized");
        require(bytes(_newBaseURI).length < (1 << 8) * 32 , "baseURI too long");

        uint256 _metadataFrozenSlot = getMetadataFrozenSlot();
        bool _metadataFrozen;
        assembly {
            _metadataFrozen := sload(_metadataFrozenSlot)
        }
        require(!_metadataFrozen, "metadata frozen");

        Operations.saveString(_newBaseURI, getBaseURISlot());
    }

    function freezeMetadata() external {
        require(msg.sender == contractOwner, "unauthorized");

        uint256 _metadataFrozenSlot = getMetadataFrozenSlot();
        bool _metadataFrozen;
        assembly {
            _metadataFrozen := sload(_metadataFrozenSlot)
        }
        if (_metadataFrozen) {
            return;
        }

        _metadataFrozen = true;
        assembly {
            sstore(_metadataFrozenSlot, _metadataFrozen)
        }
        emit MetadataFrozen();
    }

    ///////////////////// STORAGE LAYOUT FUNCTIONS ////////////////////////////

    /**
     * @custom:segment-length-bits 0
     */
    function getTotalSupplySlot() internal virtual pure returns (uint256) {
        return 2 << 8;
    }

    /**
     * @custom:segment-length-bits 0
     */
    function getMetadataFrozenSlot() internal virtual pure returns (uint256) {
        return (2 << 8) + 1;
    }

    /**
     * @custom:segment-length-bits 8
     */
    function getBaseURISlot() internal virtual pure returns (uint256) {
        return 3 << 8;
    }

}