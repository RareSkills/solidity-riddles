const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "FlashLoan tests";

describe(NAME, function () {
  async function setup() {
    const [owner, attackerWallet] = await ethers.getSigners();
    const TwentyEther = ethers.utils.parseEther("20");

    await network.provider.send("hardhat_setBalance", [
      owner.address,
      "0x56bc75e2d63100000", // 100 ether
    ]);

    const CollateralTokenFactory = await ethers.getContractFactory(
      "CollateralToken"
    );
    const collateralTokenContract = await CollateralTokenFactory.deploy();

    const createAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"; // contract address of AMM

    await collateralTokenContract.approve(
      createAddress,
      ethers.constants.MaxUint256
    );

    const AMMFactory = await ethers.getContractFactory("AMM");
    const AMMContract = await AMMFactory.deploy(
      collateralTokenContract.address,
      { value: TwentyEther }
    );
    console.log(AMMContract.address);

    return { walletContract, forwarderContract, attackerWallet };
  }

  describe("exploit", async function () {
    let walletContract,
      forwarderContract,
      attackerWallet,
      attackerWalletBalanceBefore;
    before(async function () {
      ({ walletContract, forwarderContract, attackerWallet } =
        await loadFixture(setup));
      attackerWalletBalanceBefore = await ethers.provider.getBalance(
        attackerWallet.address
      );
    });

    it("conduct your attack here", async function () {});

    after(async function () {
      const attackerWalletBalanceAfter = await ethers.provider.getBalance(
        attackerWallet.address
      );
      expect(
        attackerWalletBalanceAfter.sub(attackerWalletBalanceBefore)
      ).to.be.equal(ethers.utils.parseEther("1"));

      const walletContractBalance = await ethers.provider.getBalance(
        walletContract.address
      );
      expect(walletContractBalance).to.be.equal("0");
    });
  });
});
