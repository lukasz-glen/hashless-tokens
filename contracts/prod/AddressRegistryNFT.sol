// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {ERC721Delta} from "../segmentation/ERC721Delta.sol";
import {IAddressRegistry} from "../utils/IAddressRegistry.sol";
import {Operations} from "../utils/Operations.sol";

contract AddressRegistryNFT is ERC721Delta {
    event MetadataFrozen();

    // uint256 internal totalSupply;

    address internal immutable contractOwner;

    constructor(IAddressRegistry _addressRegistry) 
    ERC721Delta("AddressRegistryNFT", "AddrReg", _addressRegistry) {
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

        uint256 _registeredAddressSlot = getRegisteredAddressSlot(uint160(addressId));
        assembly {
            sstore(_totalSupplySlot, add(_totalSupply, 1))
            sstore(_registeredAddressSlot, caller())
        }
        _safeMint(msg.sender, addressId, data);
    }

    function getRegisteredAddress(uint256 tokenId) external view returns(address _registeredAddress) {
        if (tokenId > 2**160 - 1) {
            revert ERC721NonexistentToken(tokenId);
        }
        uint256 _registeredAddressSlot = getRegisteredAddressSlot(uint160(tokenId));
        assembly {
            _registeredAddress := sload(_registeredAddressSlot)
        }
        if (_registeredAddress == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
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

    /**
     * @custom:segment-length-bits 160
     */
    function getRegisteredAddressSlot(uint160 tokenId) internal virtual pure returns (uint256) {
        unchecked {
            return (4 << 160) + uint256(tokenId);
        }
    }

}