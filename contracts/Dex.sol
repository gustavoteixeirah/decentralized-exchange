// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Dex {
    struct Token {
        bytes32 ticker;
        address tokenAddress;
    }

    mapping(bytes32 => Token) public tokens;
    mapping(address => mapping(bytes32 => uint256)) public traderBalances;

    bytes32[] public tokenList;

    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function addToken(bytes32 _ticker, address _tokenAddress)
        external
        onlyAdmin
    {
        tokens[_ticker] = Token(_ticker, _tokenAddress);
        tokenList.push(_ticker);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function deposit(uint256 _amount, bytes32 _ticker)
        external
        payable
        tokenExist(_ticker)
    {
        IERC20(tokens[_ticker].tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        traderBalances[msg.sender][_ticker] += _amount;
    }

    function withdraw(uint256 _amount, bytes32 _ticker)
        external
        tokenExist(_ticker)
    {
        require(
            traderBalances[msg.sender][_ticker] >= _amount,
            "Balance too low."
        );
        traderBalances[msg.sender][_ticker] -= _amount;
        IERC20(tokens[_ticker].tokenAddress).transfer(msg.sender, _amount);
    }

    modifier tokenExist(bytes32 _ticker) {
        require(
            tokens[_ticker].tokenAddress != address(0),
            "This token does not exist"
        );
        _;
    }
}
