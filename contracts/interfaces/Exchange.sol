pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract Exchange {
    using SafeMath for uint;

    enum SaleType{ FIXED, AUCTION }
    struct Sale {
        uint amount;
        uint price;
    }

    // Token address -> tokenId -> seller -> SaleType
    mapping(address => mapping(uint => mapping(address => SaleType))) public saleType;
    mapping(address => mapping(uint => mapping(address => Sale))) public fixedItems;

    event ItemUpdated(address _address, uint256 _id, address _seller, uint256 _amount, uint256 _price, SaleType _type, uint256 _endTime);

    modifier HasEnoughToken(address tokenAddress, uint256 tokenId, uint256 quantity) {
        IERC1155 tokenContract = IERC1155(tokenAddress);
        require(tokenContract.balanceOf(msg.sender, tokenId) >= quantity, "Not enough token supply");
        _;
    }

    modifier HasTransferApproval(address tokenAddress, uint256 tokenId, address seller) {
        IERC1155 tokenContract = IERC1155(tokenAddress);
        require(tokenContract.isApprovedForAll(seller, address(this)), "Market not have approval of token");
        _;
    }

    function putOnSale(address _address, uint _id, uint _amount, uint _price) 
    HasEnoughToken(_address, _id, _amount) HasTransferApproval(_address, _id, msg.sender) virtual public {
        saleType[_address][_id][msg.sender] = SaleType.FIXED;
        fixedItems[_address][_id][msg.sender] = Sale(_amount, _price);
        emit ItemUpdated(_address, _id, msg.sender, _amount, _price, SaleType.FIXED, 0);
    }

    function buy(address _address, uint _id, address _seller, uint _amount) external payable {
        IERC1155 tokenContract = IERC1155(_address);
        require(saleType[_address][_id][_seller] == SaleType.FIXED, "Sale type is not fixed");
        require(fixedItems[_address][_id][_seller].amount >= _amount, "Not enough items in sale");
        require(fixedItems[_address][_id][_seller].price.mul(_amount) == msg.value, "Not enough fund to send");
        require(tokenContract.balanceOf(_seller, _id) >= _amount, "Seller not enough token supply");

        tokenContract.safeTransferFrom(_seller, msg.sender, _id, _amount, "");
        fixedItems[_address][_id][_seller].amount = fixedItems[_address][_id][_seller].amount.sub(_amount);
        payout(_address, _id, payable(_seller), msg.value);

        emit ItemUpdated(
            _address, 
            _id,
            _seller,
            fixedItems[_address][_id][_seller].amount,
            fixedItems[_address][_id][_seller].price,
            SaleType.FIXED,
            0
        );
    }

    function takeOffSale(address _address, uint _id) external {
        require(fixedItems[_address][_id][msg.sender].amount >= 0, "Item is not on sale");
        fixedItems[_address][_id][msg.sender].amount = 0;
        emit ItemUpdated(_address, _id, msg.sender, 0, fixedItems[_address][_id][msg.sender].price, SaleType.FIXED, 0);
    }

    function payout(address _collection, uint _id, address payable _seller, uint _value) internal virtual;
}
