//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Users can stake ether in ReadOnlyPool
// For each ether they contribute to the pool, they are minted an equal amount of
// LPToken.
//
// However, when the pool earns ETH, there will be more ETH
// in the pool than there are LPTokens.
//
// When someone wants to redeem their ETH, they burn their LPTokens using
// the `removeLiquidity` function. They are returned a pro-rata share of the ETH in the pool.
//
// For example, if someone deposits 100 ETH into a pool that already has 900 ETH,
// they will get back 100 LP tokens. If the pool earns 100 more ETH, there are 1000 LPTokens
// in existence, but 1,100 ETH in the pool. When someone redeems 100 LPTokens, they will actually get
// $110 ETH. (100 / 1000 == 110 / 1100).
//
// The value of an LPToken can be retrieved with `getVirtualPrice()`. As more ETH is added to the pool,
// while the supply of LP tokens is constant, the value of the LP token goes up.
//
// Because there are always at least as much ETH in the pool as there are LPTokens,
// LPTokens are always worth at least 1 ETH.
//
// Or so it seems...

// Note: This CTF was inspired by the Curve oracle attack, but has been simplified as much as possible
// to get to the core of the vulnerability, and some details have been changed. There is a flaw in this
// implementation where users instantly earn rewards if they deposit ETH into a pool that has already
// received profit, but that is not the vulnerability we are trying to exploit here.

contract VulnerableDeFiContract {
    ReadOnlyPool private pool;
    uint256 public lpTokenPrice;

    constructor(ReadOnlyPool _pool) {
        pool = _pool;
    }

    // @notice since getVirtualPrice is always correct, anyone can call it
    function snapshotPrice() external {
        lpTokenPrice = pool.getVirtualPrice();
    }
}

contract ReadOnlyPool is ReentrancyGuard, ERC20("LPToken", "LPT") {
    //IERC20[] public acceptedTokens;
    mapping(address => bool) acceptedTokens;
    mapping(address => uint256) originalStake;

    // @notice deposit eth and get back the same amount of LPTokens for later redemption
    function addLiquidity() external payable nonReentrant {
        originalStake[msg.sender] += msg.value;
        _mint(msg.sender, msg.value);
    }

    // @notice burn LPTokens and get back the original deposit of ETH + profits
    function removeLiquidity() external nonReentrant {
        uint256 numLPTokens = balanceOf(msg.sender);
        uint256 totalLPTokens = totalSupply();
        uint256 ethToReturn = (originalStake[msg.sender] * (numLPTokens + totalLPTokens)) / totalLPTokens;

        originalStake[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: ethToReturn}("");
        require(ok, "eth transfer failed");

        _burn(msg.sender, numLPTokens);
    }

    /*
     * @notice virtualPrice is the ETH in the contract divided by the total LP tokens.
     *         As more tokens are earned by the pool, the liquidity tokens are worth
     *         more because they can redeem the same size of a larger pool.
     * @dev there is always at least as much
     */

    function getVirtualPrice() external view returns (uint256 virtualPrice) {
        virtualPrice = address(this).balance / totalSupply();
    }

    // @notice earn profits for the pool
    function earnProfit() external payable {}
}
