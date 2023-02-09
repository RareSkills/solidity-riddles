interface IAMMOracle {
    function getLendTokenToEthPrice(uint) external returns (uint);

    function getEthToLendTokenPrice(uint) external returns (uint);
}
