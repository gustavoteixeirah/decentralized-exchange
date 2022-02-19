// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Dex {
    enum Side {
        BUY,
        SELL
    }

    struct Token {
        bytes32 ticker;
        address tokenAddress;
    }

    struct Order {
        uint256 id;
        Side side;
        bytes32 ticker;
        uint256 amount;
        uint256 filled;
        uint256 price;
        uint256 date;
    }

    mapping(bytes32 => Token) public tokens;
    mapping(bytes32 => mapping(uint256 => Order[])) public orderBook;
    mapping(address => mapping(bytes32 => uint256)) public traderBalances;

    bytes32[] public tokenList;

    address public admin;

    uint256 public nextOrderId;

    bytes32 constant DAI = bytes32("DAI");

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

    modifier isValidOrder(
        bytes32 _ticker,
        uint256 _amount,
        uint256 _price,
        Side _side
    ) {
        require(_ticker != DAI, "Cannot trade DAI");
        if (_side == Side.SELL) {
            require(
                traderBalances[msg.sender][_ticker] >= _amount,
                "Balance too low."
            );
        } else {
            require(
                traderBalances[msg.sender][DAI] >= _amount * _price,
                "DAI balance to low"
            );
        }
        _;
    }

    function createLimitOrder(
        bytes32 _ticker,
        uint256 _amount,
        uint256 _price,
        Side _side
    )
        external
        tokenExist(_ticker)
        isValidOrder(_ticker, _amount, _price, _side)
    {
        Order[] storage orders = orderBook[_ticker][uint256(_side)];
        orders.push(
            Order(
                nextOrderId,
                _side,
                _ticker,
                _amount,
                0,
                _price,
                block.timestamp
            )
        );
        uint256 i = orders.length - 1;
        while (i > 0) {
            if (_side == Side.BUY && orders[i - 1].price > orders[i].price) {
                break;
            }
            if (_side == Side.SELL && orders[i - 1].price < orders[i].price) {
                break;
            }
            Order memory tmp = orders[i - 1];
            orders[i - 1] = orders[i];
            orders[i] = tmp;
            i--;
        }
        nextOrderId++;
    }
}
