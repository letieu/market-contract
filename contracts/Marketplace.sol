pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/AuctionExchange.sol";
import "./interfaces/ICollectionRoyalty.sol";

contract Marketplace is AuctionExchange {
    using SafeMath for uint;

    address public marketPayee;
    uint public marketPercent;

    constructor(address _payee, uint _percent) Exchange() {
        marketPercent = _percent;
        marketPayee = _payee;
    }

    function payout(address _collection, uint _id, address payable _seller, uint _value) internal override {
        ICollectionRoyalty collection = ICollectionRoyalty(_collection);
        address payable creator = payable(collection.getCreator(_id));
        uint royalty = collection.getRoyalty(_id);
        uint decimal = collection.getDecimal();

        uint balance = _value;

        if (creator != address(0)) {
            uint creatorRevenue = _value.mul(royalty).div(100 ** decimal);
            creator.transfer(creatorRevenue);
            balance = balance.sub(creatorRevenue);
        }

        uint marketRevenue = _value.mul(marketPercent).div(100 ** 2);
        payable(marketPayee).transfer(marketRevenue);
        balance = balance.sub(marketRevenue);

        _seller.transfer(balance);
    }
}
