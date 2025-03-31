// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "../IERC20.sol";
import {IERC20Errors} from "../draft-IERC6093.sol";
import {IAddressRegistry} from "../utils/IAddressRegistry.sol";

/**
 * @title ERC20 Epsilon
 * @author @lukasz-glen
 * @notice ERC20 implementation without using keccak256
 * @dev The token does not use solidity mappings - mappings are using keccak256.
 * Variables are stored in separate segments.
 * A crucial design point: spenders' addresses are assigned to sequential ids
 * and the source of ids is an external contract (AddressRegistry) so
 * spenders' addresses are cut from 160 bits to 48 bits and allowances fit in a segment.
 * Though it costs a bit more gas.
 */
abstract contract ERC20Epsilon is IERC20, IERC20Errors {
    /**
     * @dev Indicates an error that the max total supply is exceeded. Used in mint.
     * @param sender Address whose tokens are being minted.
     * @param _totalSupply Current total supply.
     * @param value Requested value.
     */
    error ERC20TotalSupplyOverflow(address sender, uint256 _totalSupply, uint256 value);

    // the storage layout
    // single variables:
    uint256 public totalSupply;
    // area variables:
    // cannot be internal because of hardhat-exposed tests
    uint256[2**160] private _balances; // owner => balance
    // cannot be internal because of hardhat-exposed tests
    uint256[2**160 * 2**48] private _allowances; // owner x spenderId => allowance

    IAddressRegistry private immutable addressRegistry;

    constructor(IAddressRegistry _addressRegistry) {
        require(address(_addressRegistry) != address(0), "null pointer to AddressRegistry");
        addressRegistry = _addressRegistry;
    }

    /**
     * @notice ERC20 function
     */
    function balanceOf(address owner) external view returns (uint256) {
        return _balances[uint256(uint160(owner))];
    }

    /**
     * @dev for inheriting contracts, no checks
     */
    function _setBalance(address owner, uint256 value) internal {
        _balances[uint256(uint160(owner))] = value;
    }

    /**
     * @notice ERC20 function
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        uint256 _spenderId = addressRegistry.getAddressId(spender);
        // almost impossible to happen, for the sake of completness
        require(_spenderId < 1 << 48, "excessive address id");
        if (_spenderId == 0) {
            return 0;
        }
        unchecked {
            // no overflow
            return _allowances[(uint256(_spenderId) << 160) + uint256(uint160(owner))];
        }
    }

    /**
     * @notice ERC20 function
     */
    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function _approve(address owner, address spender, uint256 value) internal {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }

        uint256 _spenderId = addressRegistry.addressId(spender);
        // almost impossible to happen, for the sake of completness
        require(_spenderId < 1 << 48, "excessive address id");

        unchecked {
            // no overflow
            _allowances[(uint256(_spenderId) << 160) + uint256(uint160(owner))] = value;
        }
        emit Approval(owner, spender, value);
    }

    /**
     * @notice ERC20 function
     */
    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @notice ERC20 function
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        if (from == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }

        if (from != msg.sender) {
            _decreaseAllowance(from, msg.sender, value);
        }

        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }

        _update(from, to, value);
    }

    function _mint(address to, uint256 value) internal {
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }

        _update(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }

        _update(from, address(0), value);
    }

    function _update(address from, address to, uint256 value) internal {
        if (from != address(0)) {
            uint256 _fromBalance = _balances[uint256(uint160(from))];
            if (_fromBalance < value) {
                revert ERC20InsufficientBalance(from, _fromBalance, value);
            }
            unchecked {
                // no underflow - checked
                _balances[uint256(uint160(from))] = _fromBalance - value;
            }
        } else {
            unchecked {
                if (totalSupply + value < totalSupply) {
                    revert ERC20TotalSupplyOverflow(to, totalSupply, value);
                }
                // no overflow - checked
                totalSupply += value;
            }
        }

        if (to != address(0)) {
            uint256 _toBalance  = _balances[uint256(uint160(to))];
            unchecked {
                // no overflow - cannot exceed the total supply
                _balances[uint256(uint160(to))] = _toBalance + value;
            }
        } else {
            unchecked {
                // no underflow - by implication
                totalSupply -= value;
            }
        }

        emit Transfer(from, to, value);

    }

    function _decreaseAllowance(address owner, address spender, uint256 value) internal {
        uint256 _allowance;
        uint256 _spenderId = addressRegistry.getAddressId(spender);
        // almost impossible to happen, for the sake of completness
        require(_spenderId < 1 << 48, "excessive address id");
        if (_spenderId == 0) {
            _allowance = 0;
        } else {
            unchecked {
                // no overflow
                _allowance = _allowances[(uint256(_spenderId) << 160) + uint256(uint160(owner))];
            }
        }

        if (_allowance < value) {
            revert ERC20InsufficientAllowance(spender, _allowance, value);
        }

        if (value > 0 && _allowance < type(uint256).max) {
            unchecked {
                // no underflow - checked
                _allowances[(uint256(_spenderId) << 160) + uint256(uint160(owner))] = _allowance - value;
            }
        }
    }
}
