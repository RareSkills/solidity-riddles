// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CollateralToken is ERC20 {
    constructor() ERC20("Collateral Token", "CLT") {
        _mint(msg.sender, 5000 * 10e18);
    }
}
