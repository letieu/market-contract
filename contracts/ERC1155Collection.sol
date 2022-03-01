pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./interfaces/ERC1155Tradable.sol";
import "./interfaces/ICollectionRoyalty.sol";

contract ERC1155Collection is ERC1155Tradable, ICollectionRoyalty {
    string public contractURI;
    mapping (uint256 => uint256) public royalties;
    uint256 decimal = 2;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155Tradable(_name, _symbol) {
        contractURI = _uri;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return uris[_id];
    }

    function setRoyalty(uint256 _id, uint256 royalty) public override creatorOnly(_id) {
        royalties[_id] = royalty;
    }
    
    function getRoyalty(uint256 _id) public override view returns(uint256) {
        return royalties[_id];
    }

    function getCreator(uint256 _id) public override view returns(address) {
        return creators[_id];
    }

    function getDecimal() public view returns(uint256) {
        return decimal;
    }
}
