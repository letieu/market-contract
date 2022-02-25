pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract ERC1155Tradable is ERC1155, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _counter;
    using SafeMath for uint256;

    mapping (uint256 => address) public creators;
    mapping (uint256 => uint256) public tokenSupply;
    mapping (uint256 => string) public uris;

    string public name;
    string public symbol;

    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == msg.sender, "ERC1155Tradable#creatorOnly: ONLY_CREATOR_ALLOWED");
        _;
    }

    modifier ownersOnly(uint256 _id) {
        require(balanceOf(msg.sender, _id) > 0, "ERC1155Tradable#ownersOnly: ONLY_OWNERS_ALLOWED");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC1155("") {
        name = _name;
        symbol = _symbol;
    }

    function create(
        address _initialOwner,
        uint256 _initialSupply,
        string calldata _uri
    ) external returns (uint256) {
        uint256 _id = _counter.current();
        _counter.increment();

        _mint(_initialOwner, _id, _initialSupply, "");
        tokenSupply[_id] = _initialSupply;
        creators[_id] = msg.sender;
        uris[_id] = _uri;

        return _id;
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity
    ) public creatorOnly(_id) {
        _mint(_to, _id, _quantity, "");
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }

}
