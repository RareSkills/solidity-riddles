// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Lending.sol";

contract AMM {
    IERC20 public immutable lendToken;

    uint256 public lendTokenReserve; //Reserve0
    uint256 public ethReserve; //Reserve1

    //1 ether = 2000 usd
    //1 lend token = 100 usd
    //1 ether = 20 lend token

    /**
     * Assume that the price of ETH doesn't change throughout this CTF.
     *
     * Change in reserve ratio is therefore only as a result of
     * the lend token falling or rising in respect to ETH and not
     * ETH rising or falling in respect to lend token
     */

    constructor(address _lendToken) payable {
        // initialize
        lendToken = IERC20(_lendToken);
        require(msg.value == 20 ether, "Send 20 ether for initial Eth reserve");
        ethReserve = 20 ether;
        lendTokenReserve = 400e18;
        SafeERC20.safeTransferFrom(
            lendToken,
            msg.sender,
            address(this),
            400e18
        );
    }

    function swapLendTokenForEth(
        address to
    ) external returns (uint ethAmountOut) {
        // TAKE advantage of "donations" and avoid locked tokens
        uint256 lendTokenAmountIn = lendToken.balanceOf(address(this)) -
            lendTokenReserve;
        require(lendTokenAmountIn > 0, "Amount in cannot be zero");

        ethAmountOut = getLendTokenToEthPrice(lendTokenAmountIn);

        lendTokenReserve += lendTokenAmountIn;
        ethReserve -= ethAmountOut;

        (bool success, ) = payable(to).call{value: ethAmountOut}("");
        require(success);
    }

    function swapEthForLendToken(
        address to
    ) external payable returns (uint lendTokenAmountOut) {
        // TAKE advantage of "donations" and avoid locked tokens
        uint256 ethAmountIn = address(this).balance - ethReserve;
        require(ethAmountIn > 0, "Amount should be greater than zero");

        lendTokenAmountOut = getEthToLendTokenPrice(ethAmountIn);

        ethReserve += msg.value;
        lendTokenReserve -= lendTokenAmountOut;

        lendToken.transfer(to, lendTokenAmountOut);
    }

    function getLendTokenToEthPrice(
        uint _lendTokenAmountIn
    ) public view returns (uint _ethAmountOut) {
        _ethAmountOut =
            (ethReserve * _lendTokenAmountIn) /
            (lendTokenReserve + _lendTokenAmountIn);
    }

    function getEthToLendTokenPrice(
        uint _ethAmountIn
    ) public view returns (uint lendTokenAmountOut) {
        lendTokenAmountOut =
            (lendTokenReserve * _ethAmountIn) /
            (ethReserve + _ethAmountIn);
    }

    receive() external payable {}
}
