// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

interface IFactory {
    function getExchange(address _tokenAddress) external returns(address);
}