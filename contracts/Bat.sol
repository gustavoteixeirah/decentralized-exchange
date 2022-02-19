// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Bat is ERC20 {
    constructor(uint256 initialSupply) ERC20("BAT", "Brave browser token") {
        _mint(msg.sender, initialSupply);
    }
}
