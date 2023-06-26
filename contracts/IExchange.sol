// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

interface IExchange {
    function ethToTokenSwap(uint256 _minTokens) external payable returns(uint256);
}