// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {FirstHashlessNFTReceiver} from "./FirstHashlessNFTReceiver.sol";
import {IAddressRegistry} from "../utils/IAddressRegistry.sol";
import {FirstHashlessNFT} from "../prod/FirstHashlessNFT.sol";

contract FirstHashlessNFT_10_000_test {
    IAddressRegistry internal immutable addressRegistry;
    FirstHashlessNFT internal immutable token;

    constructor(IAddressRegistry _addressRegistry, FirstHashlessNFT _token) {
        addressRegistry = _addressRegistry;
        token = _token;
    }

    function register() external {
        new FirstHashlessNFTReceiver(0x150b7a02, addressRegistry, token).register("");
    }


}
