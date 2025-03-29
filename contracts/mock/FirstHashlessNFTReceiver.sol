// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {IERC721Receiver} from "../IERC721Receiver.sol";
import {IAddressRegistry} from "../utils/IAddressRegistry.sol";
import {FirstHashlessNFT} from "../prod/FirstHashlessNFT.sol";

contract FirstHashlessNFTReceiver is IERC721Receiver {
    bytes4 private immutable retval;
    IAddressRegistry internal immutable addressRegistry;
    FirstHashlessNFT internal immutable token;

    event Received(address operator, address from, uint256 tokenId, bytes data);

    constructor(bytes4 _retval, IAddressRegistry _addressRegistry, FirstHashlessNFT _token) {
        retval = _retval;
        addressRegistry = _addressRegistry;
        token = _token;
    }

    function register(bytes memory data) external {
        token.register(data);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4) {
        emit Received(operator, from, tokenId, data);
        return retval;
    }

}
