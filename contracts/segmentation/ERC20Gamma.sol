// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "../IERC20.sol";
import {IERC20Errors} from "../draft-IERC6093.sol";

/**
 * @title ERC20 Gamma
 * @author @lukasz-glen
 * @notice ERC20 implementation without using keccak256
 * @dev The token does not use solidity mappings - mappings are using keccak256.
 * Variables are stored in separate segments.
 * A crucial design point: the allowance is set for 160 bits of owner address and
 * 90 high bits of spender address. The remaining low 70 bits of spender address
 * is stored along with the allowance value.
 * They are for verification.
 * The benefit is that no keccak is needed.
 * The side effects are: the total supply is limited, 
 * it is not possible to have two positive approvals for the same owner and 
 * two spenders with the same 90 high bits in the address.
 */
abstract contract ERC20Gamma is IERC20, IERC20Errors {
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
    // mapping(address => mapping(uint256 => uint256)) internal allowances; // owner x (spender 90 high bits) => 
                                                                            // (spender 70 low bits) x allowance
                                                                            // 2nd segment

    uint256 private immutable level_segment;  // 252 bits length
    uint256 private constant sector_bits = 2;  // specify the segment number
    uint256 private constant spender_bits = 90;  // spender address bits in the allowance key
    uint256 private constant segment_length = 160 + spender_bits;  // the length of each segment
                                                         // enough to hold owner x (spender 90 high bits) for allowances
    uint256 private constant MAX_TOTAL_SUPPLY = (1 << (96 + spender_bits)) - 1;
    uint256 internal constant LEVEL_SEGMENT_LENGTH = sector_bits + segment_length;

    constructor(uint256 _level_segment) {
        require(
            _level_segment & ((1 << LEVEL_SEGMENT_LENGTH) - 1) == 0,
            "invalid level segment selector"
            );
        level_segment = _level_segment;
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
     * @dev The infinite allowance is stored as MAX_TOTAL_SUPPLY.
     * Any approval greater than MAX_TOTAL_SUPPLY is considered 
     * as the infinite approval.
     * For the sake of complaince, the allowance() function returns type(uint256).max
     * for the infinite allowance.
     */
    function allowance(address owner, address spender) external view returns (uint256 _allowance) {
        uint256 _allowanceSlot = getAllowanceSlot(owner, spender);
        assembly {
            _allowance := sload(_allowanceSlot)
            _allowance := xor(_allowance, shl(add(96, spender_bits), spender))
            if shr(add(96, spender_bits), _allowance) {
                _allowance := 0
            }
        }
        if (_allowance == MAX_TOTAL_SUPPLY) {
            _allowance = type(uint256).max;
        }
    }

    /**
     * @notice ERC20 function
     * @dev The infinite allowance is stored as MAX_TOTAL_SUPPLY.
     * Any approval greater than MAX_TOTAL_SUPPLY is considered 
     * as the infinite approval.
     * For the sake of complaince, the allowance() function returns type(uint256).max
     * for the infinite allowance.
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

        if (value > MAX_TOTAL_SUPPLY) {
            value = MAX_TOTAL_SUPPLY;
        }
        uint256 _allowanceSlot = getAllowanceSlot(owner, spender);
        assembly {
            sstore(_allowanceSlot, or(shl(add(96, spender_bits), spender), value))
        }
        if (value == MAX_TOTAL_SUPPLY) {
            emit Approval(owner, spender, type(uint256).max);
        } else {
            emit Approval(owner, spender, value);
        }
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
                if (_totalSupply + value > MAX_TOTAL_SUPPLY) {
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
        uint256 _allowanceSlot = getAllowanceSlot(owner, spender);
        uint256 _allowance;
        assembly {
            _allowance := sload(_allowanceSlot)
            _allowance := xor(_allowance, shl(add(96, spender_bits), spender))
            if shr(add(96, spender_bits), _allowance) {
                _allowance := 0
            }
        }

        if (_allowance < value) {
            revert ERC20InsufficientAllowance(spender, _allowance, value);
        }

        // the inifinite allowance is stored as MAX_TOTAL_SUPPLY
        if (value > 0 && _allowance < MAX_TOTAL_SUPPLY) {
            // no underflow - checked
            assembly {
                sstore(_allowanceSlot, or(shl(add(96, spender_bits), spender), sub(_allowance, value)))
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
     * @param owner an owner address
     * @param spender a spender address
     * @return slot the slot key in storage
     */
    function getAllowanceSlot(address owner, address spender) internal view returns (uint256) {
        unchecked {
            return level_segment + (2 << segment_length)
                + (uint256(uint160(owner)) << spender_bits)
                + (uint256(uint160(spender)) >> (160 - spender_bits));
        }
    }
}
