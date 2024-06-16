// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

/**
 * @title AucEngine
 * @dev This contract implements a simple auction engine.
 */
contract AucEngine {
    address public owner;
    uint constant DURATION = 2 days; // Auction duration in seconds 2 * 24 * 60 * 60
    uint constant FEE = 10; // Auction fee percentage 10%

    struct Auction {
        address payable seller;
        uint startingPrice;
        uint finalPrice;
        uint startAt;
        uint endsAt;
        uint discountRate;
        string item;
        bool stopped;
    }

    Auction[] public auctions;

    event AuctionCreated(
        uint index,
        string itemName,
        uint startingPrice,
        uint duration
    );

    event AuctionEnded(uint index, uint finalPrice, address winner);

    constructor() {
        owner = msg.sender;
    }

    function createAuction(
        uint _startingPrice,
        uint _discountRate,
        string memory _item,
        uint _duration
    ) external {
        uint duration = _duration == 0 ? DURATION : _duration;

        require(
            _startingPrice >= _discountRate * duration,
            "Incorrect starting price"
        );

        Auction memory newAuction = Auction({
            seller: payable(msg.sender),
            startingPrice: _startingPrice,
            finalPrice: _startingPrice,
            discountRate: _discountRate,
            startAt: block.timestamp,
            endsAt: block.timestamp + duration,
            item: _item,
            stopped: false
        });

        auctions.push(newAuction);

        emit AuctionCreated(
            auctions.length - 1,
            _item,
            _startingPrice,
            duration
        );
    }

    /**
     * @dev Returns the current price of an auction.
     * @param index Auction index
     */
    function getPriceFor(uint index) public view returns (uint) {
        Auction memory cAuction = auctions[index];
        require(!cAuction.stopped, "Auction stopped");
        uint elapsed = block.timestamp - cAuction.startAt;
        uint discount = cAuction.discountRate * elapsed;
        return cAuction.startingPrice - discount;
    }

    /**
     * @dev Bids on an auction.
     * @param index Auction index
     */
    function buy(uint index) external payable {
        Auction storage cAuction = auctions[index];
        require(!cAuction.stopped, "Auction stopped");
        require(block.timestamp < cAuction.endsAt, "Auction ended");
        uint cPrice = getPriceFor(index);
        require(msg.value >= cPrice, "Not enough funds");
        cAuction.stopped = true;
        cAuction.finalPrice = cPrice;
        uint refund = msg.value - cPrice;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        cAuction.seller.transfer(cPrice - ((cPrice * FEE) / 100));

        emit AuctionEnded(index, cPrice, msg.sender);
    }

    /**
     * @dev Withdraws all funds from the contract. Only the owner can call this function.
     */
    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw");
        uint balance = address(this).balance;
        payable(owner).transfer(balance);
    }
}
