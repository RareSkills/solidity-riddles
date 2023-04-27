const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "FurryFoxFriends Test";

describe(NAME, function () {
    async function setup() {
        const [, attackerWallet] = await ethers.getSigners();
        const value = ethers.utils.parseEther("1");

        const nftFactory = await ethers.getContractFactory("FurryFoxFriends");
        const nftContract = await nftFactory.deploy();

        return { nftContract, attackerWallet };
    }

    describe("exploit", async function () {
        let nftContract, attackerWallet;
        before(async function () {
            ({ walletContract, nftContract, attackerWallet } = await loadFixture(setup));
            const attackerBalance = await nftContract.balanceOf(attackerWallet.address);
            expect(attackerBalance).to.be.equal(0, "attacker starts with no NFT");
        });

        it("conduct your attack here", async function () {
            // do it
        });

        after(async function () {
            const attackerBalance = await nftContract.balanceOf(attackerWallet.address);
            expect(attackerBalance).to.be.greaterThanOrEqual(1, "attacker must acquire an NFT");
        });
    });
});
