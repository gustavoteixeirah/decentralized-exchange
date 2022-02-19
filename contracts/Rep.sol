// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Rep is ERC20 {
    constructor(uint256 initialSupply) ERC20("REP", "Augur token") {
        _mint(msg.sender, initialSupply);
    }
}
