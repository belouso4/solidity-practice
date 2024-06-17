// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

/**
 * @title ComRev
 * @dev A simple voting contract that allows users to commit and reveal their votes.
 */
contract ComRev {
    // The list of candidates for the election
    address[] public candidates = [
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];

    // Mapping of addresses to their commit hashes
    mapping(address => bytes32) public commits;

    // Mapping of addresses to their votes
    mapping(address => uint) public votes;

    // Flag to indicate if voting has stopped
    bool public votingStopped;

    /**
     * @dev Function to commit a vote
     * @param _hashedVote The hashed vote of the candidate and secret
     */
    function commitVote(bytes32 _hashedVote) external {
        require(!votingStopped);
        require(commits[msg.sender] == bytes32(0));

        commits[msg.sender] = _hashedVote;
    }

    /**
     * @dev Function to reveal a vote
     * @param _candidate The candidate the user voted for
     * @param _secret Secret hashed phrase used to generate the commit hash
     */
    function revealVote(address _candidate, bytes32 _secret) external {
        // Check if voting has stopped
        require(votingStopped);

        // Calculate the commit hash
        bytes32 commit = keccak256(
            abi.encodePacked(_candidate, _secret, msg.sender)
        );

        require(commit == commits[msg.sender]);

        // Clear the user's commit
        delete commits[msg.sender];

        // Update the vote count for the candidate
        votes[_candidate]++;
    }

    /**
     * @dev Function to stop voting
     */
    function stopVoting() external {
        require(!votingStopped);

        votingStopped = true;
    }
}
