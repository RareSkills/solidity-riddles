const { expect, use } = require("chai")
const { ethers } = require("hardhat")
const { BigNumber } = ethers
const helpers = require("@nomicfoundation/hardhat-network-helpers")

use(require("chai-as-promised"))

describe("Viceroy", async function () {
  let attackerWallet, attacker, oligarch, governance, communityWallet

  before(async function () {
    ;[_, attackerWallet] = await ethers.getSigners()

    // Name your contract GovernanceAttacker. It will be minted the NFT it needs.
    const AttackerFactory = await ethers.getContractFactory(
      "GovernanceAttacker",
    )
    attacker = await AttackerFactory.connect(attackerWallet).deploy()
    await attacker.deployed()

    const OligarchFactory = await ethers.getContractFactory("OligarchyNFT")
    oligarch = await OligarchFactory.deploy(attacker.address)
    await oligarch.deployed()

    const GovernanceFactory = await ethers.getContractFactory("Governance")
    governance = await GovernanceFactory.deploy(oligarch.address, {
      value: BigNumber.from("10000000000000000000"),
    })
    await governance.deployed()

    const walletAddress = await governance.communityWallet()
    communityWallet = await ethers.getContractAt(
      "CommunityWallet",
      walletAddress,
    )
    expect(await ethers.provider.getBalance(walletAddress)).equals(
      BigNumber.from("10000000000000000000"),
    )
  })

  // prettier-ignore;
  it("conduct your attack here", async function () {
    await attacker.attack(governance);
  });

  after(async function () {
    const walletBalance = await ethers.provider.getBalance(
      communityWallet.address,
    )
    expect(walletBalance).to.equal(0)

    const attackerBalance = await ethers.provider.getBalance(
      attackerWallet.address,
    )
    expect(attackerBalance).to.be.greaterThanOrEqual(
      BigNumber.from("10000000000000000000"),
    )

    expect(
      await ethers.provider.getTransactionCount(attackerWallet.address),
    ).to.equal(2, "must exploit in one transaction")
  })
})
