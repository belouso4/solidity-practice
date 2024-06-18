//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IERC721Receiver.sol";

contract MyContract is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
