// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IAMMOracle {
    function getLendTokenToEthPrice(uint) external returns (uint);

    function getEthToLendTokenPrice(uint) external returns (uint);
}
