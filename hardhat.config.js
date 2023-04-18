require("@nomicfoundation/hardhat-toolbox");
require("hardhat-tracer");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: {
        compilers: [
            {
                version: "0.8.15",
            },
        ],
        overrides: {
            "contracts/NameServiceBank.sol": {
                version: "0.7.0",
            },
        },
    },
};
