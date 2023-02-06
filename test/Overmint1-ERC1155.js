const {
    loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "Overmint1_ERC1155";

describe(NAME, function () {
    async function setup() {
        const [owner, attackerWallet] = await ethers.getSigners();

        const VictimFactory = await ethers.getContractFactory(NAME);
        const victimContract = await VictimFactory.deploy();

        return { victimContract, attackerWallet };
    }

    describe("exploit", async function () {
        let victimContract, attackerWallet;
        before(async function () {
            ({ victimContract, attackerWallet } = await loadFixture(setup));
        })

        it("conduct your attack here", async function () {
            const AttackerFactory = await ethers.getContractFactory("Overmint1_ERC1155_Attacker");
            const attackerContract = await AttackerFactory.connect(attackerWallet).deploy(victimContract.address);
            await attackerContract.connect(attackerWallet).attack();
        });

        after(async function () {
            expect(await victimContract.balanceOf(attackerWallet.address, 0)).to.be.equal(5);
            expect(await ethers.provider.getTransactionCount(attackerWallet.address)).to.lessThan(3, "must exploit in two transactions or less");
        });
    });
});