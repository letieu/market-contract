pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

interface ICollectionRoyalty {
    function setRoyalty(uint256 _id, uint256 royalty) external;
    
    function getRoyalty(uint256 _id) external view returns(uint256);

    function getCreator(uint256 _id) external view returns(address);

    function getDecimal() external view returns(uint256);
}