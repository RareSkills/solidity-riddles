const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "MultiDelegateCall";
const THREE_ETHER = ethers.utils.parseEther("3");

describe(NAME, function () {
  async function setup() {
    const [, user1, user2, user3, attackerWallet] = await ethers.getSigners();

    const multiDelegateCallFactory = await ethers.getContractFactory(NAME);
    const multiDelegateCallContract = await multiDelegateCallFactory.deploy();

    await multiDelegateCallContract
      .connect(user1)
      .deposit({ value: THREE_ETHER });
    await multiDelegateCallContract
      .connect(user2)
      .deposit({ value: THREE_ETHER });
    await multiDelegateCallContract
      .connect(user3)
      .deposit({ value: THREE_ETHER });

    await network.provider.send("hardhat_setBalance", [
      attackerWallet.address,
      THREE_ETHER._hex,
    ]);

    return { multiDelegateCallContract, attackerWallet };
  }

  describe("exploit", async function () {
    let multiDelegateCallContract, attackerWallet, attackerWalletBalanceBefore;

    before(async function () {
      ({ multiDelegateCallContract, attackerWallet } = await loadFixture(
        setup
      ));

      attackerWalletBalanceBefore = await ethers.provider.getBalance(
        attackerWallet.address
      );
    });

    // prettier-ignore;
    it("conduct your attack here", async function () {});

    after(async function () {
      const attackerWalletBalanceAfter = await ethers.provider.getBalance(
        attackerWallet.address
      );
      expect(
        attackerWalletBalanceAfter.sub(attackerWalletBalanceBefore)
      ).to.be.greaterThan(
        ethers.utils.parseEther("8.999"),
        "Must claim all ether to attacker wallet"
      );

      expect(
        await ethers.provider.getBalance(multiDelegateCallContract.address)
      ).to.be.equal(
        "0",
        "must claim all tokens from multiDelegateCallContract"
      );

      expect(
        await ethers.provider.getTransactionCount(attackerWallet.address)
      ).to.lessThan(3, "must exploit in two transactions or less");
    });
  });
});
