pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./Exchange.sol";

contract AuctionExchange is Exchange {
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
    // token address => token ID => seller => bidder => value
    mapping(address => mapping(uint => mapping(address => address))) public bidValues;

    event BidAdded(address _address, uint256 _id, address _seller, address _bidder, uint256 _value);
    event Withdrawn(address _address, uint256 _id, address _seller, address _bidder, uint256 _value);

    constructor(address _payee, uint _fee) Exchange(_payee, _fee) {}

    // Auction sale
    function putOnSale(address _address, uint _id, uint _amount, uint _minPrice, uint _endTime)
    HasEnoughToken(_address, _id, _amount) HasTransferApproval(_address, _id, msg.sender) external {
        require(fixedItems[_address][_id][msg.sender].amount == 0, "Token is in fixed sale");
        saleType[_address][_id][msg.sender] = SaleType.AUCTION;
        auctionItems[_address][_id][msg.sender] = Auction(_amount, _minPrice, address(0), _endTime, false);
        emit ItemUpdated(_address, _id, msg.sender, _amount, _minPrice, SaleType.AUCTION, _endTime);
    }

    // Fixed sale
    function putOnSale(address _address, uint _id, uint _amount, uint _price)
    HasEnoughToken(_address, _id, _amount) HasTransferApproval(_address, _id, msg.sender) public override {
        require(auctionItems[_address][_id][msg.sender].ended == true, "Token is in auction sale");
        super.putOnSale(_address, _id, _amount, _price);
    }

    function bid(address _address, uint _id, address _seller) external payable {
        require(saleType[_address][_id][_seller] == SaleType.AUCTION, "Token not in auction");
        require(auctionItems[_address][_id][_seller].ended != true, "Auction ended");
        require(block.timestamp <= auctionItems[_address][_id][_seller].endTime, "Auction expired");

        uint newBidValue = bidValues[_address][_id][_seller][msg.sender].add(msg.value);
        require(auctionItems[_address][_id][_seller].maxBid < newBidValue, "There already is a higher bid");

        bidValues[_address][_id][_seller][msg.sender] = newBidValue;
        auctionItems[_address][_id][_seller].maxBid = newBidValue;
        auctionItems[_address][_id][_seller].maxBidder = msg.sender;

        emit BidAdded(_address, _id, _seller, msg.sender, newBidValue);
    }

    function endAuction(address _address, uint _id, address _seller) external {
        IERC1155 tokenContract = IERC1155(_address);
        require(saleType[_address][_id][_seller] == SaleType.AUCTION, "Token not in auction");
        require(auctionItems[_address][_id][_seller].ended != true, "Auction ended");
        require(block.timestamp > auctionItems[_address][_id][_seller].endTime, "Auction not expired");
        require(tokenContract.balanceOf(_seller, _id) >= auctionItems[_address][_id][_seller].amount, "Seller not enough token supply"); // TODO: if not enough, refund

        tokenContract.safeTransferFrom(_seller, msg.sender, _id, auctionItems[_address][_id][_seller].amount, "");
        // Pay for creator and marketplace
    }

    function withDraw(address _address, uint _id, address _seller) external {
        require(auctionItems[_address][_id][_seller].maxBidder != msg.sender, "Max bidder cannot withdraw");
        payable(msg.sender).transfer(bidValues[_address][_id][_seller][msg.sender]);
        emit Withdrawn(_address, _id, _seller, msg.sender, bidValues[_address][_id][_seller][msg.sender]);
    }
}
