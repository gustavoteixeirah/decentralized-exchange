// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Dai is ERC20 {
    constructor(uint256 initialSupply) ERC20("DAI", "Dai Stablecoin") {
        _mint(msg.sender, initialSupply);
    }

    function faucet(address to, uint amount) external {
    _mint(to, amount);
  }
}
