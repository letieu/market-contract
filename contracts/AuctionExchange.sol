pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./Exchange.sol";

contract AuctionExchange is Exchange {
    using SafeMath for uint;

    struct Auction {
        uint maxBid;
        address maxBidder;
        uint endTime;
    }

    // token address => token ID => seller => value
    mapping(address => mapping(uint => mapping(address => Auction))) auctionItems;
    mapping(address => mapping(uint => mapping(address => uint))) bidValue;

    constructor(address _payee, uint _fee) Exchange(_payee, _fee) {}

    function putOnSale(address _address, uint _id, uint _amount, uint _minPrice, uint _endTime) external {
        auctionItems[_address][_id][msg.sender] = Auction(_minPrice, address(0), _endTime);
        bidValue[_address][_id][msg.sender] = bidValue[_address][_id][msg.sender].add(_amount);
    }

    function withDraw(address _address, uint _id, address _seller) external {
        // 
    }

    function bid(address _address, uint _id, address _seller, uint value) external {
        // 
    }
}