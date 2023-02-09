// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AMMOracle {
    IERC20 public immutable lendToken;

    uint256 public lendTokenReserve; //R0
    uint256 public ethReserve; //R1

    //1 ether = 2000 usd
    //1 ether = 2,476 lend token
    //1 lend token = 100 usd
    constructor(address _lendToken) payable {
        lendToken = IERC20(_lendToken);
        require(msg.value == 20 ether, "Send 20 ether for initial Eth reserve");
        ethReserve = msg.value;
        lendToken.transferFrom(msg.sender, address(this), 400 * 1e18);
        lendTokenReserve = lendToken.balanceOf(address(this));
    }

    function swapLendTokenForEth(
        uint lendTokenAmountIn
    ) external returns (uint ethAmountOut) {
        require(lendTokenAmountIn > 0, "Amount in cannot be zero");

        lendToken.transferFrom(msg.sender, address(this), lendTokenAmountIn);
        ethAmountOut = getLendTokenToEthPrice(lendTokenAmountIn);

        lendTokenReserve += lendTokenAmountIn;
        ethReserve -= ethAmountOut;

        (bool success, ) = payable(msg.sender).call{value: ethAmountOut}("");
        require(success);
    }

    function swapEthForLendToken(
        uint ethAmountIn
    ) external payable returns (uint lendTokenAmountOut) {
        require(ethAmountIn > 0, "Amount should be greater than zero");
        require(msg.value == ethAmountIn, "Provide the right amount");
        lendTokenAmountOut = getEthToLendTokenPrice(ethAmountIn);

        ethReserve += msg.value;
        lendTokenReserve -= lendTokenAmountOut;

        lendToken.transfer(msg.sender, lendTokenAmountOut);
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
