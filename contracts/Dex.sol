// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Dex {
    event NewTrade(
        uint256 _tradeId,
        uint256 _orderId,
        bytes32 indexed _ticker,
        address indexed _trader1,
        address indexed _trader2,
        uint256 _amount,
        uint256 _price,
        uint256 _date
    );

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
        address trader;
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
    uint256 public nextTradeId;

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
    modifier notDai(bytes32 _ticker) {
        require(_ticker != DAI, "Cannot trade DAI");
        _;
    }

    modifier isValidOrder(
        bytes32 _ticker,
        uint256 _amount,
        uint256 _price,
        Side _side
    ) {
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
        notDai(_ticker)
        isValidOrder(_ticker, _amount, _price, _side)
    {
        Order[] storage orders = orderBook[_ticker][uint256(_side)];
        orders.push(
            Order(
                nextOrderId,
                msg.sender,
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

    function createMarketOrder(
        bytes32 _ticker,
        uint256 _amount,
        Side _side
    ) external tokenExist(_ticker) notDai(_ticker) {
        if (_side == Side.SELL) {
            require(
                traderBalances[msg.sender][_ticker] >= _amount,
                "Balance too low."
            );
        }
        Order[] storage orders = orderBook[_ticker][
            uint256(_side == Side.BUY ? Side.SELL : Side.BUY)
        ];
        uint256 i;
        uint256 remaining = _amount;
        while (i < orders.length && remaining > 0) {
            uint256 available = orders[i].amount - orders[i].filled;
            uint256 matched = (remaining > available) ? available : remaining;
            remaining -= matched;
            orders[i].filled += matched;
            emit NewTrade(
                nextTradeId,
                orders[i].id,
                _ticker,
                orders[i].trader,
                msg.sender,
                matched,
                orders[i].price,
                block.timestamp
            );
            if (_side == Side.SELL) {
                traderBalances[msg.sender][_ticker] -= matched;
                traderBalances[msg.sender][DAI] += matched * orders[i].price;
                traderBalances[orders[i].trader][_ticker] += matched;
                traderBalances[orders[i].trader][DAI] -=
                    matched *
                    orders[i].price;
            }
            if (_side == Side.BUY) {
                require(
                    traderBalances[msg.sender][DAI] >=
                        matched * orders[i].price,
                    "DAI balance too low"
                );
                traderBalances[msg.sender][_ticker] += matched;
                traderBalances[msg.sender][DAI] -= matched * orders[i].price;
                traderBalances[orders[i].trader][_ticker] -= matched;
                traderBalances[orders[i].trader][DAI] +=
                    matched *
                    orders[i].price;
            }
            nextTradeId++;
            i++;
        }
        i = 0;
        while (i < orders.length && orders[i].filled == orders[i].amount) {
            for (uint256 j = i; j < orders.length - 1; j++) {
                orders[j] = orders[j + 1];
            }
            orders.pop();
            i++;
        }
    }
}
