// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.22 <0.9.0;

// Uncomment this line to use console.log
import "hardhat/console.sol";

/// @title Payments
/// @notice A contract for handling payments
contract Payments {
    address owner;

    /// @dev Struct to store the details of a payment
    struct Payment {
        uint amount;
        uint timestamp;
        address from;
        string message;
    }

    /// @dev Struct to store the balance details of an address
    struct Balance {
        uint totalPayments;
        mapping(uint => Payment) payments;
    }

    /// @dev Mapping to store the balances of different addresses
    mapping(address => Balance) public balances;

    constructor() {
        owner = msg.sender;
    }

    /// @notice Get the current balance of the contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    /// @notice Get a payment made by an address
    function getPayment(
        address _addr,
        uint _index
    ) public view returns (Payment memory) {
        return balances[_addr].payments[_index];
    }

    /// @notice Make a payment
    function pay(string memory message) external payable returns (uint) {
        uint paymentNum = balances[msg.sender].totalPayments;
        balances[msg.sender].totalPayments++;

        Payment memory newPayment = Payment(
            msg.value,
            block.timestamp,
            msg.sender,
            message
        );

        balances[msg.sender].payments[paymentNum] = newPayment;

        return msg.value;
    }

    /// @notice Withdraw all contract funds to a specified address.
    function withdraw(address payable _to) external {
        require(owner == msg.sender, "You are not an owner!");
        require(getBalance() > 0, "Not enough money!");
        _to.transfer(getBalance());
    }
}
