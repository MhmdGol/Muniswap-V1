// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import './Exchange.sol';
import './IFactory.sol';


contract Factory is IFactory {
    mapping (address => address) public tokenToExchange;

    function createExchange(address _tokenAddress) public returns(address) {
        require(_tokenAddress != address(0), "Invalid tokne address");
        require(
            tokenToExchange[_tokenAddress] == address(0),
            "The exchange exists"
        );

        Exchange exchange = new Exchange(_tokenAddress);
        tokenToExchange[_tokenAddress] = address(exchange);
        return address(exchange);
    }

    function getExchange(address _tokenAddress) public view override returns(address) {
        return tokenToExchange[_tokenAddress];
    }
}