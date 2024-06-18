//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IERC165.sol";

contract ERC165 is IERC165 {
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
