// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721} from "../IERC721.sol";
import {IERC721Metadata} from "../IERC721Metadata.sol";
import {IERC721Receiver} from "../IERC721Receiver.sol";
import {IERC165} from "../IERC165.sol";
import {IERC721Errors} from "../draft-IERC6093.sol";
import {IAddressRegistry} from "../utils/IAddressRegistry.sol";
import {Operations} from "../utils/Operations.sol";

import "hardhat/console.sol";

abstract contract ERC721Delta is IERC721, IERC721Metadata, IERC721Errors {
    // the storage layout
    // area variables:
    // string internal name;
    // string internal symbol;
    // mapping(address owner => uint256) internal balances;
    // mapping(uint256 tokenId => address) internal owners;
    // mapping(uint256 tokenId => address) internal allowances;
    // mapping(address owner => mapping(address operator => bool)) internal operators;  // owner x spenderId => allowance

    IAddressRegistry internal immutable addressRegistry;

    constructor(string memory name_, string memory symbol_, IAddressRegistry _addressRegistry) {
        require(address(_addressRegistry) != address(0), "null pointer to AddressRegistry");
        addressRegistry = _addressRegistry;

        require(bytes(name_).length < (1 << 8) * 32 , "name too long");
        require(bytes(symbol_).length < (1 << 8) * 32, "symbol too long");

        // _name = name_;
        // _symbol = symbol_;
        Operations.saveString(name_, getNameSlot());
        Operations.saveString(symbol_, getSymbolSlot());
    }

    /**
     * @notice ERC721 function
     */
    function balanceOf(address owner) external view returns (uint256 _balance) {
        if (owner == address(0)) {
            revert ERC721InvalidOwner(address(0));
        }
        uint256 _balanceSlot = getBalanceSlot(owner);
        assembly {
            _balance := sload(_balanceSlot)
        }
    }

    /**
     * @notice ERC721 function
     */
    function ownerOf(uint256 tokenId) external view returns (address _owner) {
        if (tokenId > 2**160 - 1) {
            revert ERC721NonexistentToken(tokenId);
        }
        uint256 _ownerSlot = getOwnerSlot(uint160(tokenId));
        assembly {
            _owner := sload(_ownerSlot)
        }
        if (_owner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
    }

    /**
     * @notice ERC721 function
     */
    function getApproved(uint256 tokenId) external view returns (address _operator) {
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
        uint256 _allwanceSlot = getAllowanceSlot(uint160(tokenId));
        assembly {
            _operator := sload(_allwanceSlot)
        }        
    }

    function approve(address to, uint256 tokenId) external {
        _approve(to, tokenId, msg.sender);
    }

    function _approve(address to, uint256 tokenId, address auth) internal {
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
        if (_owner != auth) {
            uint256 _operatorId = addressRegistry.getAddressId(auth);
            // almost impossible to happen, for the sake of completness
            require(_operatorId < 1 << 48, "excessive address id");
            if (_operatorId == 0) {
                revert ERC721InvalidApprover(auth);
            }
            uint256 _operatorSlot = getOperatorSlot(_owner, uint48(_operatorId));
            bool _isOperator;
            assembly {
                _isOperator := sload(_operatorSlot)
            }
            if (!_isOperator) {
                revert ERC721InvalidApprover(auth);
            }
        }
        
        uint256 _allowanceSlot = getAllowanceSlot(uint160(tokenId));
        assembly {
            sstore(_allowanceSlot, to)
        }
        emit Approval(_owner, to, tokenId);
    }

    /**
     * @notice ERC721 function
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool _isOperator) {
        uint256 _operatorId = addressRegistry.getAddressId(operator);
        // almost impossible to happen, for the sake of completness
        require(_operatorId < 1 << 48, "excessive address id");
        if (_operatorId == 0) {
            return false;
        }
        uint256 _operatorSlot = getOperatorSlot(owner, uint48(_operatorId));
        assembly {
            _isOperator := sload(_operatorSlot)
        }
    }

    /**
     * @notice ERC721 function
     */
    function setApprovalForAll(address operator, bool approved) external {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        if (operator == address(0)) {
            revert ERC721InvalidOperator(operator);
        }
        uint256 _operatorId = addressRegistry.addressId(operator);
        // almost impossible to happen, for the sake of completness
        require(_operatorId < 1 << 48, "excessive address id");

        uint256 _operatorSlot = getOperatorSlot(owner, uint48(_operatorId));
        assembly {
            sstore(_operatorSlot, approved)
        }
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @notice ERC721 function
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external{
        transferFrom(from, to, tokenId);
        checkOnERC721Received(msg.sender, from, to, tokenId, data);
    }

    /**
     * @notice ERC721 function
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        transferFrom(from, to, tokenId);
        checkOnERC721Received(msg.sender, from, to, tokenId, "");
    }

    function _safeTransfer(address from, address to, uint256 tokenId) internal {
        _transfer(from, to, tokenId);
        checkOnERC721Received(msg.sender, from, to, tokenId, "");
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        checkOnERC721Received(msg.sender, from, to, tokenId, data);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
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
        if (_owner != from) {
            revert ERC721IncorrectOwner(from, tokenId, _owner);
        }
        
        _update(to, tokenId);
    }

    /**
     * @notice ERC721 function
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
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
        if (_owner != from) {
            revert ERC721IncorrectOwner(from, tokenId, _owner);
        }
        address operator = msg.sender;
        if (operator != _owner) {
            uint256 _operatorId = addressRegistry.getAddressId(operator);
            // almost impossible to happen, for the sake of completness
            require(_operatorId < 1 << 48, "excessive address id");
            bool _isOperator;
            if (_operatorId == 0) {
                _isOperator = false;
            } else {
                uint256 _operatorSlot = getOperatorSlot(_owner, uint48(_operatorId));
                assembly {
                    _isOperator := sload(_operatorSlot)
                }
            }
            if (!_isOperator) {
                uint256 _allowanceSlot = getAllowanceSlot(uint160(tokenId));
                address _approved;
                assembly {
                    _approved := sload(_allowanceSlot)
                }
                if (operator != _approved) {
                    revert ERC721InsufficientApproval(operator, tokenId);
                }
            }
        }

        _update(to, tokenId);
    }

    /**
     * @dev no authorization here
     */
    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        if (tokenId > 2**160 - 1) {
            revert("invalid tokenId");
        }
        uint256 _ownerSlot = getOwnerSlot(uint160(tokenId));
        address _owner;
        assembly {
            _owner := sload(_ownerSlot)
        }
        if (_owner != address(0)) {
            revert ERC721InvalidSender(address(0));
        }

        _update(to, tokenId);
    }

    /**
     * @dev no authorization here
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _mint(to, tokenId);
        checkOnERC721Received(msg.sender, address(0), to, tokenId, "");
    }

    /**
     * @dev no authorization here
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        checkOnERC721Received(msg.sender, address(0), to, tokenId, data);
    }

    /**
     * @dev no allowance check here
     */
    function _burn(uint256 tokenId) internal {
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

        _update(address(0), tokenId);
    }

    function _update(address to, uint256 tokenId) internal virtual {
        uint256 _ownerSlot = getOwnerSlot(uint160(tokenId));
        address from;
        assembly {
            from := sload(_ownerSlot)
        }

        if (from != address(0)) {
            uint256 _allowanceSlot = getAllowanceSlot(uint160(tokenId));
            uint256 _balanceFromSlot = getBalanceSlot(from);
            assembly {
                sstore(_allowanceSlot, 0)
                sstore(_balanceFromSlot, sub(sload(_balanceFromSlot), 1))
            }
        }

        if (to != address(0)) {
            uint256 _balanceToSlot = getBalanceSlot(to);
            assembly {
                sstore(_balanceToSlot, add(sload(_balanceToSlot), 1))
            }
        }

        assembly {
            sstore(_ownerSlot, to)
        }
        emit Transfer(from, to, tokenId);
    }

    /**
     * @notice ERC165 function
     */
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    /**
     * OpenZeppelin
     */
    function checkOnERC721Received(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(operator, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    // Token rejected
                    revert IERC721Errors.ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // non-IERC721Receiver implementer
                    revert IERC721Errors.ERC721InvalidReceiver(to);
                } else {
                    assembly ("memory-safe") {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /**
     * @notice IERC721Metadata function
     */
    function name() public view virtual returns (string memory) {
       return Operations.loadString(getNameSlot());
    }

    /**
     * @notice IERC721Metadata function
     */
    function symbol() public view virtual returns (string memory) {
        return Operations.loadString(getSymbolSlot());
    }

    /**
     * @notice IERC721Metadata function
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
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

        string memory baseURI = _baseURI();
        if (bytes(baseURI).length == 0) {
            return "";
        }

        string memory ptr;
        assembly {
            let baseURILen := mload(baseURI)

            ptr := mload(0x40)
            // Note that Solidity generated IR code reserves memory offset ``0x60`` as well, but a pure Yul object is free to use memory as it chooses.
            if iszero(ptr) {
                ptr := 0x60
            }
            // decimal representation of uint256 has less than 80 digits
            ptr := add(add(add(ptr, 32), baseURILen), 0x50)
            mstore(0x40, ptr)
            let oldPtr := ptr

            switch tokenId
            case 0 {
                ptr := sub(ptr, 1)
                mstore8(ptr, 0x30)
            }
            default {
                for { let value := tokenId } gt(value, 0x0) { value := div(value, 10) } {
                    ptr := sub(ptr, 1)
                    mstore8(ptr, add(0x30, mod(value, 10)))
                }
            }

            // the last word
            let baseURIPtr := add(baseURI, baseURILen)
            // technical trick
            baseURILen := add(baseURILen, 0x20)
            for {} gt(baseURILen, 0x20) {} {
                ptr := sub(ptr, 0x20)
                mstore(ptr, mload(baseURIPtr))
                baseURIPtr := sub(baseURIPtr, 0x20)
                baseURILen := sub(baseURILen, 0x20)
            }

            // now it points a word with length
            ptr := sub(ptr, baseURILen)
            // the old free memory pointer stores the end of concatenated string
            let len := sub(oldPtr, add(ptr, 0x20))
            mstore(ptr, len)
        }
        return ptr;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    
    ///////////////////// STORAGE LAYOUT FUNCTIONS ////////////////////////////

    /**
     * @custom:segment-length-bits 8
     */
    function getNameSlot() internal virtual pure returns (uint256) {
        return 0;
    }

    /**
     * @custom:segment-length-bits 8
     */
    function getSymbolSlot() internal virtual pure returns (uint256) {
        return 1 << 8;
    }

    /**
     * @custom:segment-length-bits 160
     */
    function getBalanceSlot(address owner) internal virtual pure returns (uint256) {
        unchecked {
            return (1 << 160) + uint256(uint160(owner));
        }
    }

    /**
     * @custom:segment-length-bits 160
     */
    function getOwnerSlot(uint160 tokenId) internal virtual pure returns (uint256) {
        unchecked {
            return (2 << 160) + uint256(tokenId);
        }
    }

    /**
     * @custom:segment-length-bits 160
     */
    function getAllowanceSlot(uint160 tokenId) internal virtual pure returns (uint256) {
        unchecked {
            return (3 << 160) + uint256(tokenId);
        }
    }

    /**
     * @custom:segment-length-bits 208
     */
    function getOperatorSlot(address owner, uint48 _spenderId) internal virtual pure returns (uint256) {
        unchecked {
            return (1 << 208) + (uint256(_spenderId) << 160) + uint256(uint160(owner));
        }
    }    
}
