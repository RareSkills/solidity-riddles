const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const NAME = "FlashLoan tests";
const OneHundred_Ether = "0x56bc75e2d63100000";

describe(NAME, function () {
  async function setup() {
    const [owner, lender, borrower] = await ethers.getSigners();
    const TwentyEther = ethers.utils.parseEther("20");

    await network.provider.send("hardhat_setBalance", [
      lender.address,
      OneHundred_Ether, // 100 ether
    ]);

    const CollateralTokenFactory = await ethers.getContractFactory(
      "CollateralToken"
    );
    const collateralTokenContract = await CollateralTokenFactory.deploy();

    // get AMM address before deployment as we call transferFrom in its constructor so it needs to be approved
    const createAddress =
      "0x" +
      ethers.utils
        .keccak256(
          ethers.utils.RLP.encode([
            owner.address,
            ethers.utils.hexZeroPad(
              (await ethers.provider.getTransactionCount(owner.address)) + 1
              // + 1 because we approve first before deploying it
            ),
          ])
        )
        .slice(26);
    //"0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"; contract address of AMM

    await collateralTokenContract.approve(
      createAddress,
      ethers.constants.MaxUint256
    );

    const AMMFactory = await ethers.getContractFactory("AMM");
    const AMMContract = await AMMFactory.deploy(
      collateralTokenContract.address,
      { value: TwentyEther }
    );

    const LendingFactory = await ethers.getContractFactory("Lending");
    const LendingContract = await LendingFactory.deploy(AMMContract.address);

    const FlashLoanFactory = await ethers.getContractFactory("FlashLender");
    const FlashLoanContract = await FlashLoanFactory.deploy(
      [collateralTokenContract.address],
      0
    );

    // INIT FLASHLOAN CONTRACT: SEND 500 lend tokens to flashloan contract
    await collateralTokenContract.transfer(
      FlashLoanContract.address,
      ethers.utils.parseEther("500")
    );

    // owner deposits collateral to lending contract to be borrowable
    // can also be done by calling LendingContract.addLiquidity() but this is cheaper because no calldata to pay for
    await owner.sendTransaction({
      value: ethers.utils.parseEther("6"),
      to: LendingContract.address,
      data: "0x",
    });

    // Send 500 tokens to borrower for collateral
    await collateralTokenContract.transfer(
      borrower.address,
      ethers.utils.parseEther("500")
    );

    // Use borrower to approve lending contract
    await collateralTokenContract
      .connect(borrower)
      .approve(LendingContract.address, ethers.constants.MaxUint256);

    // borrower takes loan and pays 240 tokens as collateral
    await LendingContract.connect(borrower).borrowEth(
      ethers.utils.parseEther("6")
    );

    return {
      FlashLoanContract,
      LendingContract,
      AMMContract,
      collateralTokenContract,
      borrower,
      lender,
    };
  }

  describe("exploit", async function () {
    let FlashLoanContract,
      LendingContract,
      AMMContract,
      collateralTokenContract,
      borrower,
      lender;

    before(async function () {
      ({
        FlashLoanContract,
        LendingContract,
        AMMContract,
        collateralTokenContract,
        borrower,
        lender,
      } = await loadFixture(setup));
    });

    // prettier-ignore
    it("conduct your attack here", async function () {
      
    });

    after(async function () {
      /**
       * Requirements:
       * - Liquidate and take all collateral from lending contract and send to lender wallet
       * - Do this in 2 transactions or less?
       */
      const difference = (
        await collateralTokenContract.balanceOf(lender.address)
      ).sub(ethers.utils.parseEther("240")); // 240e18

      const pass = difference.gte(ethers.BigNumber.from(-30));

      expect(pass).to.be.equal(true, "Must take all of borrower's collateral");

      expect(
        await collateralTokenContract.balanceOf(LendingContract.address)
      ).to.be.equal(0, "must fully drain lending contract");

      expect(
        await ethers.provider.getTransactionCount(lender.address)
      ).to.lessThan(3, "must exploit in two transactions or less");
    });
  });
});
