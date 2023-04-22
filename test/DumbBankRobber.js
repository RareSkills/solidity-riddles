const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "DumbBank";

describe(NAME, function () {
    async function setup() {
        const [owner, attackerWallet] = await ethers.getSigners();

        const VictimFactory = await ethers.getContractFactory(NAME);
        const victimContract = await VictimFactory.deploy();
        await victimContract.deposit({ value: ethers.utils.parseEther("10") });

        return { victimContract, attackerWallet };
    }

    describe("exploit", async function () {
        let victimContract, attackerWallet;
        before(async function () {
            ({ victimContract, attackerWallet } = await loadFixture(setup));
        });

        // you should not modify this function
        // the attack happens from the constructor
        it("conduct your attack here", async function () {
            const AttackFactory = await ethers.getContractFactory("BankRobber");
            await AttackFactory.connect(attackerWallet).deploy(victimContract.address, {
                value: ethers.utils.parseEther("1"),
            });
        });

        after(async function () {
            expect(await ethers.provider.getBalance(victimContract.address)).to.be.equal(0);
            expect(await ethers.provider.getTransactionCount(attackerWallet.address)).to.equal(
                1,
                "must exploit one transaction"
            );
        });
    });
});
