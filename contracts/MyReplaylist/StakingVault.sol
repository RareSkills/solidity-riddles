// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract StakingVault {
    using ECDSA for bytes32;
    IERC20 token;

    constructor(address _token) {
        token = IERC20(_token);
    }

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public nonce;

    function deposit(uint256 amount) external payable {
        balanceOf[msg.sender] += amount;
        token.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address payable to, uint256 amount) external {
        _withdraw(msg.sender, to, amount);
    }

    function withdrawWithPermit(
        address owner,
        address payable to,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 hash = keccak256(abi.encode(owner, to, amount, nonce[owner]++));
        require(owner == ECDSA.recover(hash.toEthSignedMessageHash(), v, r, s), "StakingVault: Owner not signer");

        _withdraw(owner, to, amount);
    }

    function _withdraw(address owner, address payable to, uint256 amount) private {
        uint256 fromBalance = balanceOf[owner];
        require(fromBalance >= amount, "StakingVault: Insufficient Balance");
        unchecked {
            balanceOf[owner] = fromBalance - amount;
        }
        token.transfer(to, amount);
    }

    function getEthSignedMessageHash(bytes32 hash) private pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
