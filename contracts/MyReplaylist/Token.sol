// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(string memory _name, string memory _symbol, uint256 mintAmount) ERC20(_name, _symbol) {
        _mint(msg.sender, mintAmount);
    }
}
