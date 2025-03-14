// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "../IERC20.sol";
import {IERC20Errors} from "../draft-IERC6093.sol";
import {IAddressRegistry} from "../utils/IAddressRegistry.sol";

/**
 * @title ERC20 Beta
 * @author @lukasz-glen
 * @notice ERC20 implementation without using keccak256
 * @dev The token does not use solidity mappings - mappings are using keccak256.
 * Variables are stored in separate segments.
 * A crucial design point: spenders' addresses are assigned to sequential ids
 * and the source of ids is an external contract (AddressRegistry) so
 * spenders' addresses are cut from 160 bits to 48 bits and allowances fit in a segment.
 * Though it costs a bit more gas.
 */
abstract contract ERC20Beta is IERC20, IERC20Errors {
    /**
     * @dev Indicates an error that the max total supply is exceeded. Used in mint.
     * @param sender Address whose tokens are being minted.
     * @param totalSupply Current total supply.
     * @param value Requested value.
     */
    error ERC20TotalSupplyOverflow(address sender, uint256 totalSupply, uint256 value);

    // the storage layout
    // single variables (zero segment):
    // uint256 public totalSupply;
    // area variables:
    // mapping(address => uint256) internal balances; // 1st segment
    // mapping(address => mapping(uint256 => uint256)) internal allowances; // owner x spenderId => allowance
                                                                            // 2nd segment

    uint256 private immutable level_segment;  // 210 bits length
    IAddressRegistry private immutable addressRegistry;
    uint256 private constant sector_bits = 2;  // specify the segment number
    uint256 private constant segment_length = 160 + 48;  // the length of each segment
                                                         // enough to hold owner x spenderId for allowances

    constructor(uint256 _level_segment, IAddressRegistry _addressRegistry) {
        require(
            _level_segment & ((1 << (sector_bits + segment_length)) - 1) == 0,
            "invalid level segment selector"
            );
        require(address(_addressRegistry) != address(0), "null pointer to AddressRegistry");

        level_segment = _level_segment;
        addressRegistry = _addressRegistry;
    }

    /**
     * @notice ERC20 function
     */
    function totalSupply() external view returns (uint256 _totalSupply) {
        uint256 _totalSupplySlot = getTotalSupplySlot();
        assembly {
            _totalSupply := sload(_totalSupplySlot)
        }
    }

    /**
     * @notice ERC20 function
     */
    function balanceOf(address owner) external view returns (uint256 _balance) {
        uint256 _balanceSlot = getBalanceSlot(owner);
        assembly {
            _balance := sload(_balanceSlot)
        }
    }

    /**
     * @notice ERC20 function
     */
    function allowance(address owner, address spender) external view returns (uint256 _allowance) {
        uint256 _spenderId = addressRegistry.getAddressId(spender);
        // almost impossible to happen, for the sake of completness
        require(_spenderId < 1 << 48, "excessive address id");
        if (_spenderId == 0) {
            return 0;
        }
        uint256 _allowanceSlot = getAllowanceSlot(owner, _spenderId);
        assembly {
            _allowance := sload(_allowanceSlot)
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
        uint256 _allowanceSlot = getAllowanceSlot(owner, _spenderId);
        assembly {
            sstore(_allowanceSlot, value)
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
            uint256 _fromBalance;
            uint256 _fromBalanceSlot = getBalanceSlot(from);
            assembly {
                _fromBalance := sload(_fromBalanceSlot)
            }
            if (_fromBalance < value) {
                revert ERC20InsufficientBalance(from, _fromBalance, value);
            }
            // no underflow - checked
            assembly{
                sstore(_fromBalanceSlot, sub(_fromBalance, value))
            }
        } else {
            uint256 _totalSupply;
            uint256 _totalSupplySlot = getTotalSupplySlot();
            assembly {
                _totalSupply := sload(_totalSupplySlot)
            }
            unchecked {
                if (_totalSupply + value < _totalSupply) {
                    revert ERC20TotalSupplyOverflow(to, _totalSupply, value);
                }
            }
            // no overflow - checked
            assembly{
                sstore(_totalSupplySlot, add(_totalSupply, value))
            }            
        }

        if (to != address(0)) {
            uint256 _toBalance;
            uint256 _toBalanceSlot = getBalanceSlot(to);
            assembly {
                _toBalance := sload(_toBalanceSlot)
            }
            // no overflow - cannot exceed the total supply
            assembly{
                sstore(_toBalanceSlot, add(_toBalance, value))
            }
        } else {
            uint256 _totalSupply;
            uint256 _totalSupplySlot = getTotalSupplySlot();
            assembly {
                _totalSupply := sload(_totalSupplySlot)
            }
            // no underflow - by implication
            assembly{
                sstore(_totalSupplySlot, sub(_totalSupply, value))
            }
        }

        emit Transfer(from, to, value);

    }

    function _decreaseAllowance(address owner, address spender, uint256 value) internal {
        uint256 _allowance;
        uint256 _allowanceSlot = 0;
        uint256 _spenderId = addressRegistry.getAddressId(spender);
        // almost impossible to happen, for the sake of completness
        require(_spenderId < 1 << 48, "excessive address id");
        if (_spenderId == 0) {
            _allowance = 0;
        } else {
            _allowanceSlot = getAllowanceSlot(owner, _spenderId);
            assembly {
                _allowance := sload(_allowanceSlot)
            }
        }

        if (_allowance < value) {
            revert ERC20InsufficientAllowance(spender, _allowance, value);
        }

        if (value > 0 && _allowance < type(uint256).max) {
            // no underflow - checked
            assembly {
                sstore(_allowanceSlot, sub(_allowance, value))
            }
        }
    }

    ///////////////////// STORAGE LAYOUT HELPERS ////////////////////////////

    function getTotalSupplySlot() internal view returns (uint256) {
        return level_segment;
    }

    function getBalanceSlot(address owner) internal view returns (uint256) {
        unchecked {
            return level_segment + (1 << segment_length) + uint256(uint160(owner));
        }
    }

    /**
     * Calculates the slot key in storage for owner x spender.
     * A spender is given as a spender id.
     * The spender id is not validated, this is an internal function.
     * @param owner an owner address
     * @param _spenderId a spender address, must fit in 48 bits
     * @return slot the slot key in storage
     */
    function getAllowanceSlot(address owner, uint256 _spenderId) internal view returns (uint256) {
        unchecked {
            return level_segment + (2 << segment_length) + (_spenderId << 160) + uint256(uint160(owner));
        }
    }
}
