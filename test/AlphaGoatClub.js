const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "Alpha Goat Club";

describe(NAME, function () {
    async function setup() {
        const [, attacker] = await ethers.getSigners();

        const AlphaGoatClub = await (await ethers.getContractFactory("AlphaGoatClubPrototypeNFT")).deploy();

        return {
            attacker,
            AlphaGoatClub,
        };
    }

    describe("exploit", async function () {
        let attacker, AlphaGoatClub;

        before(async function () {
            ({ attacker, AlphaGoatClub } = await loadFixture(setup));
        });

        it("conduct your attack here", async function () {
            // Your exploit here
            /**
             * The goal is to use the attacker wallet to mint the NFT at index 0 to itself.
             */
        });

        after(async function () {
            expect(await AlphaGoatClub.ownerOf(0)).to.equal(attacker.address);

            expect(await ethers.provider.getTransactionCount(attacker.address)).to.lessThan(
                3,
                "must exploit in two transactions or less"
            );
        });
    });
});
