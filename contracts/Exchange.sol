pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Exchange {
    using SafeMath for uint;

    enum SaleType{ FIXED, AUCTION }
    struct Sale {
        uint amount;
        uint price;
    }

    // Token address -> tokenId -> seller -> SaleType
    mapping(address => mapping(uint => mapping(address => SaleType))) saleType;
    mapping(address => mapping(uint => mapping(address => Sale))) fixedItems;

    address marketPayee;
    uint marketFee;

    constructor(address _payee, uint _fee) {
        marketPayee = _payee;
        marketFee = _fee;
    }

    function putOnSale(address _address, uint _id, uint _amount, uint _price) external {
        fixedItems[_address][_id][msg.sender] = Sale(_amount, _price);
    }

    function buy(address _address, uint _id, address _seller, uint _amount) external {
        IERC1155 tokenContract = IERC1155(_address);
        // Check balance;
        // check quantity in sale
        tokenContract.safeTransferFrom(_seller, msg.sender, _id, _amount, "");
        // Pay for creator and marketplace
    }
}