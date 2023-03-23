const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "AssignVotes";

describe(NAME, function () {
  async function setup() {
    const [owner, assignerWallet, attackerWallet] = await ethers.getSigners();

    const VictimFactory = await ethers.getContractFactory(NAME);
    const victimContract = await VictimFactory.deploy({
      value: ethers.utils.parseEther("1"),
    });

    return { victimContract, assignerWallet, attackerWallet };
  }

  describe("exploit", async function () {
    let victimContract, assignerWallet, attackerWallet;
    before(async function () {
      ({ victimContract, assignerWallet, attackerWallet } = await loadFixture(
        setup
      ));
      await victimContract
        .connect(assignerWallet)
        .assign("0x976EA74026E726554dB657fA54763abd0C3a0aa9");
      await victimContract
        .connect(assignerWallet)
        .assign("0x14dC79964da2C08b23698B3D3cc7Ca32193d9955");
      await victimContract
        .connect(assignerWallet)
        .assign("0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f");
      await victimContract
        .connect(assignerWallet)
        .assign("0xa0Ee7A142d267C1f36714E4a8F75612F20a79720");
      await victimContract
        .connect(assignerWallet)
        .assign("0xBcd4042DE499D14e55001CcbB24a551F3b954096");
    });

    // you may only use the attacker wallet, and no other wallet
    it("conduct your attack here", async function () {});

    after(async function () {
      expect(
        await ethers.provider.getBalance(victimContract.address)
      ).to.be.equal(0);
      expect(
        await ethers.provider.getTransactionCount(attackerWallet.address)
      ).to.equal(1, "must exploit one transaction");
    });
  });
});
