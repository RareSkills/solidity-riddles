const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "MyReplaylist";

describe(NAME, function () {
    async function setup() {
        const [daiDeployer, lusdDeployer, attackerWallet] = await ethers.getSigners();

        /**
         * DAI Stablecoin launched their token alongside a vault contract
         */
        const dai = await (
            await ethers.getContractFactory("Token")
        ).deploy("Dai Stablecoin", "DAI", ethers.utils.parseEther("100000"));
        const daiStakingVault = await (await ethers.getContractFactory("StakingVault")).deploy(dai.address);

        // the deployer testing some cool functionalities after deploying it
        await dai.approve(daiStakingVault.address, ethers.constants.MaxUint256);
        await daiStakingVault.deposit(ethers.utils.parseEther("20000"));
        await daiStakingVault.withdraw(daiDeployer.address, ethers.utils.parseEther("10000"));

        // wanting to test withdrawing to another address, daiDeployer decided to send it to a random address picked from a twitter comment on his post
        const signature = await daiDeployer.signMessage(
            ethers.utils.arrayify(
                ethers.utils.keccak256(
                    ethers.utils.defaultAbiCoder.encode(
                        ["address", "address", "uint256", "uint256"],
                        [
                            daiDeployer.address,
                            attackerWallet.address,
                            ethers.utils.parseEther("10000"),
                            await daiStakingVault.nonce(daiDeployer.address),
                        ]
                    )
                )
            )
        );
        await daiStakingVault.withdrawWithPermit(
            daiDeployer.address,
            attackerWallet.address,
            ethers.utils.parseEther("10000"),
            parseInt(ethers.utils.hexDataSlice(signature, 64, 66)),
            ethers.utils.hexDataSlice(signature, 0, 32),
            ethers.utils.hexDataSlice(signature, 32, 64)
        );

        /**
         * A year later, LUSD forked DAI's code with no modifications to leverage on DAI's time tested code. They deployed a stablecoin and staking vault.
         */
        const lusd = await (await ethers.getContractFactory("Token"))
            .connect(lusdDeployer)
            .deploy("Liquity Stablecoin", "LUSD", ethers.utils.parseEther("100000"));
        const lusdStakingVault = await (await ethers.getContractFactory("StakingVault")).deploy(lusd.address);

        // dai-deployer decided to try it out with some lusd which lusd-deployer gladly sent over
        await lusd.transfer(daiDeployer.address, ethers.utils.parseEther("20000"));

        // daiDeployer tests out depositing and withdrawing, and leaves some lusd there after testing
        await lusd.connect(daiDeployer).approve(lusdStakingVault.address, ethers.constants.MaxUint256);
        await lusdStakingVault.connect(daiDeployer).deposit(ethers.utils.parseEther("20000"));
        await lusdStakingVault.connect(daiDeployer).withdraw(daiDeployer.address, ethers.utils.parseEther("10000"));

        return { dai, lusd, daiStakingVault, lusdStakingVault, daiDeployer, attackerWallet };
    }

    describe("exploit", async function () {
        let dai, lusd, daiStakingVault, lusdStakingVault, daiDeployer, attackerWallet;
        before(async function () {
            ({ dai, lusd, daiStakingVault, lusdStakingVault, daiDeployer, attackerWallet } = await loadFixture(setup));
        });

        it("conduct your attack here", async function () {
            // conduct your attack here
            // the task is to drain daiDeployer's lusdStakingVault balance.
        });

        after(async function () {
            expect(await lusdStakingVault.balanceOf(daiDeployer.address)).to.equal(
                ethers.utils.parseEther("0"),
                "Not exploited"
            );
            expect(await lusd.balanceOf(attackerWallet.address)).to.equal(
                ethers.utils.parseEther("10000"),
                "Not exploited"
            );
            expect(await ethers.provider.getTransactionCount(attackerWallet.address)).to.lessThan(
                2,
                "must exploit in one transaction"
            );
        });
    });
});
