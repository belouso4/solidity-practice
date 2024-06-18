//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

/**
 * @title MyToken
 * @dev Implementation of the ERC721 standard with enumerable extension and URI storage.
 */
contract MyToken is ERC721, ERC721Enumerable, ERC721URIStorage {
    address public owner;
    uint currentTokenId;

    constructor() ERC721("MyToken", "MTK") {
        owner = msg.sender;
    }

    /**
     * @dev Safely mints a new token.
     */
    function safeMint(address to, string calldata tokenId) public {
        require(owner == msg.sender, "not an owner!");

        _safeMint(to, currentTokenId);
        _setTokenURI(currentTokenId, tokenId);

        currentTokenId++;
    }

    /**
     * @dev Overrides the supportsInterface function to check if the contract supports the interface.
     * @return True if the contract supports the interface, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the base URI for the token URIs.
     */
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    /**
     * @dev Burns the token.
     */
    function _burn(uint tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /**
     * @dev Returns the token URI.
     */
    function tokenURI(
        uint tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
