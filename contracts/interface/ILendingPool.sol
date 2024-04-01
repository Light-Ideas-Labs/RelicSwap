// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILendingPool {
    function deposit (address _reserve, uint256 _amount, address onBehalfOf, uint16 _referralCode) external payable override {
        // Implementation goes here

    
    };
    function withdraw (address _reserve, uint256 _amount, address payable to) external override {
        // Implementation goes here

    
    
    };
    function getBalance(address _reserve, address _user) external view returns (uint256) override {
        // Implementation goes here
    };
}