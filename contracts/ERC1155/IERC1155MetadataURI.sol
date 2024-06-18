// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "./IERC1155.sol";

interface IERC1155MetadataURI is IERC1155 {
    function uri(uint id) external view returns (string memory);
}
