// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.22 <0.9.0;

/**
 * @title Tree
 * @dev Contract for creating a Merkle tree from a list of transactions.
 */
contract Tree {
    /**
     * @dev Array of hashes representing each transaction in the tree.
     */
    bytes32[] public hashes;

    /**
     * @dev Array of transactions to be hashed and included in the tree.
     */
    string[4] transactions = [
        "TX1: Sherlock -> John",
        "TX2: John -> Sherlock",
        "TX3: John -> Mary",
        "TX3: Mary -> Sherlock"
    ];

    /**
     * @dev Constructor that initializes the hashes array by hashing each
     * transaction and adding it to the array.
     */
    constructor() {
        for (uint i = 0; i < transactions.length; i++) {
            hashes.push(makeHash(transactions[i]));
        }

        uint count = transactions.length;
        uint offset = 0;

        while (count > 0) {
            for (uint i = 0; i < count - 1; i += 2) {
                hashes.push(
                    keccak256(
                        abi.encodePacked(
                            hashes[offset + i],
                            hashes[offset + i + 1]
                        )
                    )
                );
            }
            offset += count;
            count = count / 2;
        }
    }

    /**
     * @dev Verify that a given transaction is included in the tree by checking
     * that the computed hash of the transaction matches the given root hash.
     *
     * @param transaction The transaction to be verified.
     * @param index The index of the transaction in the list of transactions.
     * @param root The root hash of the tree.
     * @param proof An array of intermediate hashes that prove the inclusion of
     * the transaction in the tree.
     * @return True if the computed hash matches the given root hash, false
     * otherwise.
     */
    function verify(
        string memory transaction,
        uint index,
        bytes32 root,
        bytes32[] memory proof
    ) public pure returns (bool) {
        bytes32 hash = makeHash(transaction);
        for (uint i = 0; i < proof.length; i++) {
            bytes32 element = proof[i];
            if (index % 2 == 0) {
                hash = keccak256(abi.encodePacked(hash, element));
            } else {
                hash = keccak256(abi.encodePacked(element, hash));
            }
            index = index / 2;
        }
        return hash == root;
    }

    /**
     * @dev Compute the hash of a given input string.
     *
     * @param input The input string to be hashed.
     * @return The computed hash.
     */
    function makeHash(string memory input) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(input));
    }
}
