pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./Exchange.sol";

abstract contract AuctionExchange is Exchange {
    using SafeMath for uint;

    struct Auction {
        uint amount;
        uint maxBid;
        address maxBidder;
        uint endTime;
        bool ended;
    }

    // token address => token ID => seller => value
    mapping(address => mapping(uint => mapping(address => Auction))) public auctionItems;

    mapping(address => uint) public pendingWithdraws;

    event BidAdded(address _address, uint256 _id, address _seller, address _bidder, uint256 _value);
    event Withdrawn(address _bidder, uint256 _value);
    event AuctionEnded(address _address, uint256 _id, address _seller, address _maxBidder, uint256 _maxBid, uint256 _amount, bool _success);

    function putOnAuction(address _address, uint _id, uint _amount, uint _minPrice, uint _endTime)
    HasEnoughToken(_address, _id, _amount) HasTransferApproval(_address, _id, msg.sender) external {
        require(fixedItems[_address][_id][msg.sender].amount == 0, "Token is in fixed sale");
        saleType[_address][_id][msg.sender] = SaleType.AUCTION;

        auctionItems[_address][_id][msg.sender] = Auction(_amount, _minPrice, address(0), _endTime, false);
        emit ItemUpdated(_address, _id, msg.sender, _amount, _minPrice, SaleType.AUCTION, _endTime);
    }

    function putOnSale(address _address, uint _id, uint _amount, uint _price)
    HasEnoughToken(_address, _id, _amount) HasTransferApproval(_address, _id, msg.sender) public override {
        bool isInAuction = (auctionItems[_address][_id][msg.sender].ended != true) && (auctionItems[_address][_id][msg.sender].amount > 0);
        require(isInAuction == false, "Token is in auction sale");
        super.putOnSale(_address, _id, _amount, _price);
    }

    function bid(address _address, uint _id, address _seller) external payable {
        require(saleType[_address][_id][_seller] == SaleType.AUCTION, "Token not in auction");
        require(auctionItems[_address][_id][_seller].ended != true, "Auction ended");
        require(block.timestamp <= auctionItems[_address][_id][_seller].endTime, "Auction expired");

        require(auctionItems[_address][_id][_seller].maxBid < msg.value, "There already is a higher bid");

        pendingWithdraws[auctionItems[_address][_id][_seller].maxBidder] = pendingWithdraws[msg.sender].add(auctionItems[_address][_id][_seller].maxBid);

        auctionItems[_address][_id][_seller].maxBid = msg.value;
        auctionItems[_address][_id][_seller].maxBidder = msg.sender;

        emit BidAdded(_address, _id, _seller, msg.sender, msg.value);
    }

    function endAuction(address _address, uint _id, address _seller) external {
        IERC1155 tokenContract = IERC1155(_address);
        require(saleType[_address][_id][_seller] == SaleType.AUCTION, "Token not in auction");
        require(auctionItems[_address][_id][_seller].ended != true, "Auction ended");
        require(block.timestamp > auctionItems[_address][_id][_seller].endTime, "Auction not expired");
        require(tokenContract.balanceOf(_seller, _id) >= auctionItems[_address][_id][_seller].amount, "Seller not enough token supply"); // TODO: if not enough, refund

        tokenContract.safeTransferFrom(_seller, auctionItems[_address][_id][_seller].maxBidder, _id, auctionItems[_address][_id][_seller].amount, "");
        payout(_address, _id, payable(_seller), auctionItems[_address][_id][_seller].maxBid);
        auctionItems[_address][_id][_seller].ended = true;
    }

    function withdraw() external {
        payable(msg.sender).transfer(pendingWithdraws[msg.sender]);
        emit Withdrawn(msg.sender, pendingWithdraws[msg.sender]);
        pendingWithdraws[msg.sender] = 0;
    }
}
