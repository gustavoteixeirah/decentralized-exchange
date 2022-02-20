// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Zrx is ERC20 {
    constructor(uint256 initialSupply) ERC20("ZRX", "0x token") {
        _mint(msg.sender, initialSupply);
    }

    function faucet(address to, uint amount) external {
    _mint(to, amount);
  }
}
