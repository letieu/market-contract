pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./ERC1155Tradable.sol";

contract ERC1155Collection is ERC1155Tradable {
    string public contractURI;

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

}
