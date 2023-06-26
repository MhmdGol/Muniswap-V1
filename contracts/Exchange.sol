// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol';
import './IFactory.sol';
import './IExchange.sol';

contract Exchange is ERC20, IExchange {
    address public tokenAddress;
    address public factoryAddress;

    constructor(address _token) ERC20("Muniswap-V1", "MUNI-V1") {
        require(_token != address(0), "Invalid token address");

        tokenAddress = _token;
        factoryAddress = msg.sender;
    }

    function addLiquidity(uint _tokenAmount) external payable {
        if (getReserve() == 0) {
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), _tokenAmount);
        
        uint256 liquidity = address(this).balance;
        _mint(msg.sender, liquidity);

        } else {
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserve();
            uint256 tokenAmount = msg.value * tokenReserve / ethReserve;
            require(_tokenAmount >= tokenAmount, "Insufficient token amount");

            IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);

            uint256 liquidity = totalSupply() * msg.value / ethReserve;
            _mint(msg.sender, liquidity);
        }
    }

    function getReserve() public view returns(uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns(uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Invalid reserve");

        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;
    }

    function getTokenAmount(uint256 _ethSold) public view returns(uint256) {
        require(_ethSold > 0, "Invalid input");
        uint256 tokenReserve = getReserve();
        return getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    function getEthAmount(uint256 _tokenSold) public view returns(uint256) {
        require(_tokenSold > 0, "Invalid input");
        uint256 tokenReserve = getReserve();
        return getAmount(_tokenSold, tokenReserve, address(this).balance); 
    }

    function ethToTokenSwap(uint256 _minTokens) public payable override returns(uint256) {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = getAmount(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );
        require(tokensBought >= _minTokens, "Insufficient output amount");

        IERC20(tokenAddress).transfer(msg.sender, tokensBought);
        return tokensBought;
    }

    function tokenToEthSwap(uint256 _tokenSold, uint256 _minEth) public payable returns(uint256) {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(
            _tokenSold,
            tokenReserve,
            address(this).balance
        );
        require(ethBought >= _minEth, "Insufficient output amount");

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenSold);
        payable(msg.sender).transfer(ethBought);
        return ethBought;
    }

    function removeLiquidity(uint256 _amountWithrawn) public payable {
        require(_amountWithrawn > 0, "Insufficient liquidity");

        uint256 ethWithrawn = address(this).balance * _amountWithrawn / totalSupply();
        uint256 tokenWithrawn = getReserve() * _amountWithrawn / totalSupply();

        _burn(msg.sender, _amountWithrawn);
        payable(msg.sender).transfer(ethWithrawn);
        IERC20(tokenAddress).transfer(msg.sender, tokenWithrawn);
    }

    function tokenToTokenSwap(
        uint256 _tokenSold, 
        uint256 _minTokensBought, 
        address _tokenAddress
    ) public payable {
        // (, bytes memory data) = factoryAddress.call(abi.encodeWithSignature("getExchange(address)", _tokenAddress));
        // Exchange exchangeAddress = Exchange(abi.decode(data, (address)));

        address exchangeAddress = IFactory(factoryAddress).getExchange(_tokenAddress);
        require(
            exchangeAddress != address(this) && exchangeAddress != address(0),
            "Invalid exchange address"
        );
        
        uint256 tokenReserve = getReserve();
        uint256 ethAmount = getAmount(
            _tokenSold,
            tokenReserve,
            address(this).balance
        );
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenSold);

        uint256 tokensBought = IExchange(exchangeAddress).ethToTokenSwap{value: ethAmount}(_minTokensBought);
        IERC20(_tokenAddress).transfer(msg.sender, tokensBought);
    }
}