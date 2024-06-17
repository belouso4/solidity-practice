// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

/**
 * @title Timelock
 * @dev A contract that allows the owner to queue and execute transactions after a certain delay.
 */
contract Timelock {
    uint constant MINIMUM_DELAY = 10;
    uint constant MAXIMUM_DELAY = 1 days;
    uint constant GRACE_PERIOD = 1 days;
    address public owner;
    string public message;
    uint public amount;

    mapping(bytes32 => bool) public queue;

    modifier onlyOwner() {
        require(msg.sender == owner, "not an owner!");
        _;
    }

    event Queued(bytes32 txId);
    event Discarded(bytes32 txId);
    event Executed(bytes32 txId);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Function that will be added to timelock
     */
    function demo(string calldata _msg) external payable {
        message = _msg;
        amount = msg.value;
    }

    /**
     * @dev Returns the current timestamp plus 60 seconds.
     */
    function getNextTimestamp() external view returns (uint) {
        return block.timestamp + 60;
    }

    /**
     * @dev Returns the encoded data for a transaction.
     */
    function prepareData(
        string calldata _msg
    ) external pure returns (bytes memory) {
        return abi.encode(_msg);
    }

    /**
     * @dev Adds a transaction to the queue.
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
        // Calculate the transaction ID
        bytes32 txId = keccak256(
            abi.encode(_to, _func, _data, _value, _timestamp)
        );

        require(!queue[txId], "already queued");

        // Add the transaction to the queue
        queue[txId] = true;

        emit Queued(txId);

        return txId;
    }

    /**
     * @dev Executes a transaction from the queue.
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

        // Calculate the transaction ID
        bytes32 txId = keccak256(
            abi.encode(_to, _func, _data, _value, _timestamp)
        );

        require(queue[txId], "not queued!");

        delete queue[txId];

        // Encode the data for the transaction
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
     * @dev Discards a transaction from the queue.
     */
    function discard(bytes32 _txId) external onlyOwner {
        require(queue[_txId], "not queued");

        delete queue[_txId];

        emit Discarded(_txId);
    }
}
