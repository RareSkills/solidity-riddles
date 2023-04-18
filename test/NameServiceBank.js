const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "Name Service Bank";
const OneHundred_Ether = "0x56bc75e2d63100000";

describe(NAME, function () {
    async function setup() {
        const [attacker, victim] = await ethers.getSigners();
        const TwentyEther = ethers.utils.parseEther("20");

        await network.provider.send("hardhat_setBalance", [
            victim.address,
            OneHundred_Ether, // 100 ether
        ]);

        await victim.sendTransaction({
            to: attacker.address,
            value: ethers.utils.parseEther("1"),
        });

        const nameServiceBank = await (await ethers.getContractFactory("NAME_SERVICE_BANK")).connect(victim).deploy();

        const now = await time.latest();
        await nameServiceBank
            .connect(victim)
            .setUsername("samczsun", 0, [now + 120, now], { value: ethers.utils.parseEther("1") });
        await nameServiceBank.connect(victim).deposit({ value: TwentyEther });

        // make attack contract named "NameServiceAttacker" deployed by attacker wallet
        const NameServiceAttacker = await (
            await ethers.getContractFactory("NameServiceAttacker")
        ).deploy(nameServiceBank.address);

        return {
            nameServiceBank,
            TwentyEther,
            NameServiceAttacker,
        };
    }

    describe("exploit", async function () {
        let bankBalanceOfBefore, NameServiceAttackerBalanceOfBefore, nameServiceBank, TwentyEther, NameServiceAttacker;

        before(async function () {
            ({ nameServiceBank, TwentyEther, NameServiceAttacker } = await loadFixture(setup));
            bankBalanceOfBefore = ethers.utils.parseUnits(
                ethers.utils.formatEther(await network.provider.send("eth_getBalance", [nameServiceBank.address]))
            );
            NameServiceAttackerBalanceOfBefore = ethers.utils.parseUnits(
                ethers.utils.formatEther(await network.provider.send("eth_getBalance", [NameServiceAttacker.address]))
            );
        });

        it("conduct your attack here", async function () {
            // Your exploit here
            // You will may create an attacking smart contract(s) but
            // You may not modify any other part of the test or the
            // contract you are attacking.
            // We've already written the JS code above to deploy a
            // contract called "NameServiceAttacker" for you.
        });

        after(async function () {
            const bankBalanceAfter = ethers.utils.parseUnits(
                ethers.utils.formatEther(await ethers.provider.getBalance(nameServiceBank.address))
            );
            const NameServiceAttackerBalanceAfter = ethers.utils.parseUnits(
                ethers.utils.formatEther(await ethers.provider.getBalance(NameServiceAttacker.address))
            );

            expect(bankBalanceOfBefore.sub(bankBalanceAfter)).to.equal(TwentyEther);

            expect(NameServiceAttackerBalanceAfter.sub(NameServiceAttackerBalanceOfBefore)).to.equal(TwentyEther);

            expect(await ethers.provider.getTransactionCount(NameServiceAttacker.address)).to.lessThan(
                3,
                "must exploit in two transactions or less"
            );
        });
    });
});
