// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

contract MultiDelegateCall {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(amount <= balances[msg.sender], "insufficient balance");
        balances[msg.sender] -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "withdraw failed");
    }

    function multicall(bytes[] calldata data) external payable {
        bool success;
        for (uint256 i = 0; i < data.length; i++) {
            (success, ) = address(this).delegatecall(data[i]);
            require(success, "Call failed");
        }
    }
}
