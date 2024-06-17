// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

/**
 * @title MultiSig
 * @dev A multi-signature contract that allows multiple owners to approve transactions.
 */
contract MultiSig {
    // Minimum delay between transactions in seconds
    uint constant MINIMUM_DELAY = 10;
    // Maximum delay between transactions in seconds
    uint constant MAXIMUM_DELAY = 1 days;
    // Grace period after the timelock expires in seconds
    uint constant GRACE_PERIOD = 1 days;
    address[] public owners;
    mapping(address => bool) public isOwner;
    // Message that can be set by the demo function
    string public message;
    // Amount of Ether that can be set by the demo function
    uint public amount;
    // Number of confirmations required to execute a transaction
    uint public constant CONFIRMATIONS_REQUIRED = 3;

    // Structure representing a transaction
    struct Transaction {
        bytes32 uid;
        address to;
        uint value;
        bytes data;
        uint confirmations;
    }

    mapping(bytes32 => Transaction) public txs;

    // Mapping of transaction IDs to the confirmations for each owner
    mapping(bytes32 => mapping(address => bool)) public confirmations;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not an owner!");
        _;
    }

    event Queued(bytes32 txId);
    event Discarded(bytes32 txId);
    event Executed(bytes32 txId);

    /**
     * @dev Constructor that initializes the contract with the given owners
     * @param _owners An array of addresses that will be set as owners
     */
    constructor(address[] memory _owners) {
        require(_owners.length >= CONFIRMATIONS_REQUIRED, "not enough owners!");

        for (uint i = 0; i < _owners.length; i++) {
            address nextOwner = _owners[i];

            require(
                nextOwner != address(0),
                "cant have zero address as owner!"
            );
            require(!isOwner[nextOwner], "duplicate owner!");

            isOwner[nextOwner] = true;
            owners.push(nextOwner);
        }
    }

    /**
     * @dev Function that sets the message and amount variables
     */
    function demo(string calldata _msg) external payable {
        message = _msg;
        amount = msg.value;
    }

    /**
     * @dev Function that returns the next timestamp
     */
    function getNextTimestamp() external view returns (uint) {
        return block.timestamp + 60;
    }

    /**
     * @dev Function that prepares data for a transaction
     */
    function prepareData(
        string calldata _msg
    ) external pure returns (bytes memory) {
        return abi.encode(_msg);
    }

    /**
     * @dev Adds a transaction to the queue
     */
    function addToQueue(
        address _to,
        string calldata _func,
        bytes calldata _data,
        uint _value,
        uint _timestamp
    ) external onlyOwner returns (bytes32) {
        require(
            _timestamp > block.timestamp + MINIMUM_DELAY &&
                _timestamp < block.timestamp + MAXIMUM_DELAY,
            "invalid timestamp"
        );
        // Calculate the unique identifier of the transaction
        bytes32 txId = keccak256(
            abi.encode(_to, _func, _data, _value, _timestamp)
        );

        // Check transaction is not already queued
        require(txs[txId].to == address(0), "already queued");

        txs[txId] = Transaction({
            uid: txId,
            to: _to,
            value: _value,
            data: _data,
            confirmations: 0
        });

        emit Queued(txId);

        return txId;
    }

    /**
     * @dev Confirms a transaction
     * @param _txId Unique identifier of the transaction
     */
    function confirm(bytes32 _txId) external onlyOwner {
        require(txs[_txId].to != address(0), "not queued!");
        require(!confirmations[_txId][msg.sender], "already confirmed!");

        Transaction storage transaction = txs[_txId];
        transaction.confirmations++;
        confirmations[_txId][msg.sender] = true;
    }

    /**
     * @dev Cancels a confirmation for a transaction
     */
    function cancelConfirmation(bytes32 _txId) external onlyOwner {
        require(txs[_txId].to != address(0), "not queued!");
        require(confirmations[_txId][msg.sender], "not confirmed!");

        Transaction storage transaction = txs[_txId];
        transaction.confirmations--;
        confirmations[_txId][msg.sender] = false;
    }

    /**
     * @dev Executes a transaction
     */
    function execute(
        address _to,
        string calldata _func,
        bytes calldata _data,
        uint _value,
        uint _timestamp
    ) external payable onlyOwner returns (bytes memory) {
        require(block.timestamp > _timestamp, "too early");
        require(_timestamp + GRACE_PERIOD > block.timestamp, "tx expired");

        // Calculate the unique identifier of the transaction
        bytes32 txId = keccak256(
            abi.encode(_to, _func, _data, _value, _timestamp)
        );

        require(txs[txId].to != address(0), "not queued!");

        Transaction storage transaction = txs[txId];

        require(
            transaction.confirmations >= CONFIRMATIONS_REQUIRED,
            "not enough confirmations!"
        );

        // Delete transaction from the queue
        delete txs[txId];

        // Prepare data for the transaction
        bytes memory data;
        if (bytes(_func).length > 0) {
            data = abi.encodePacked(bytes4(keccak256(bytes(_func))), _data);
        } else {
            data = _data;
        }

        // Execute the transaction
        (bool success, bytes memory resp) = _to.call{value: _value}(data);
        require(success);

        emit Executed(txId);
        return resp;
    }

    /**
     * @dev Cancels a transaction and removes it from the queue
     */
    function discard(bytes32 _txId) external onlyOwner {
        require(txs[_txId].to != address(0), "not queued!");

        // Delete transaction from the queue
        delete txs[_txId];

        emit Discarded(_txId);
    }
}
