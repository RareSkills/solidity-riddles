// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./AMM.sol";

// assume this is a private pool where only one address can provide LP
contract Lending {
    AMM public immutable oracle;
    address public immutable lender;

    // important to avoid division/modulo by 0 panic errors
    uint16 private constant collateralContext = 1_000;
    uint16 private constant overcollateralizationMultiplier = 2_000;
    uint16 private constant liquidationThreshold = 1_500;

    struct LoanInfo {
        uint256 collateralBalance;
        uint256 borrowedAmount;
    }

    mapping(address => LoanInfo) public userToLoanInfo;

    // deployer is sole lender
    constructor(address _oracle) {
        oracle = AMM(payable(_oracle));
        lender = msg.sender;
    }

    // can be solved using shares msg.value as sqrt(k)
    function addLiquidity() external payable {}

    function removeLiquidity(uint256 amount) external {
        require(msg.sender == lender, "UNAUTHORIZED");
        require(amount <= address(this).balance, "Insufficient balance");

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success);
    }

    // assume user borrows all collateral borrowable
    // an address can only have one loan at a time (can be dynamic with loan IDs)
    function borrowEth(
        uint256 ethAmount
    ) external returns (uint256 lendTokenCollateral) {
        require(
            ethAmount > 0 && ethAmount <= address(this).balance,
            "Invalid amount"
        );
        require(
            userToLoanInfo[msg.sender].borrowedAmount == 0,
            "Repay existing loan"
        );

        // (lendQuote / ethBorrowed) = (lendReserve / ethReserve)
        // lendQuote = (lendReserve * ethBorrowed) / ethReserve
        uint256 lendQuote = (oracle.lendTokenReserve() * ethAmount) /
            oracle.ethReserve();

        // overcollaterize collateral using overcollateralizationMultiplier
        lendTokenCollateral =
            (lendQuote * overcollateralizationMultiplier) /
            collateralContext;

        // update borrower info
        userToLoanInfo[msg.sender] = LoanInfo({
            collateralBalance: lendTokenCollateral,
            borrowedAmount: ethAmount
        });

        // transfer collateral in
        SafeERC20.safeTransferFrom(
            oracle.lendToken(),
            msg.sender,
            address(this),
            lendTokenCollateral
        );

        // transfer loan
        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        require(success);
    }

    // borrower's loan to liquidate
    function liquidate(address borrower) external {
        LoanInfo memory loanInfo = userToLoanInfo[borrower];
        IERC20 token = oracle.lendToken();
        require(loanInfo.borrowedAmount > 0, "Nothing to liquidate");

        uint256 lendQuote = (oracle.lendTokenReserve() *
            loanInfo.borrowedAmount) / oracle.ethReserve();

        uint256 collateralRequired = (lendQuote * liquidationThreshold) /
            collateralContext;

        require(
            loanInfo.collateralBalance < collateralRequired,
            "Not undercollaterized"
        );

        uint256 amount = lendQuote <= token.balanceOf(address(this))
            ? lendQuote
            : loanInfo.collateralBalance;

        userToLoanInfo[borrower] = LoanInfo(0, 0);

        // transfer owed amount to liquidator (msg.sender)
        SafeERC20.safeTransfer(token, msg.sender, amount);

        // transfer left overs to borrower if any
        if (loanInfo.collateralBalance != amount) {
            SafeERC20.safeTransfer(
                oracle.lendToken(),
                msg.sender,
                loanInfo.collateralBalance - lendQuote
            );
        }
    }

    // When ether is sent, it is used to pay off msg.sender's loan if any
    // if msg.sender has no borrowed amount or sends more than that, it is seen as a donation
    // Lender can use this to add more liquidity to pool
    receive() external payable {
        // if value sent is less than msg.sender's loan, reduce owed amount
        if (msg.value < userToLoanInfo[msg.sender].borrowedAmount) {
            userToLoanInfo[msg.sender].borrowedAmount -= msg.value;
        } else {
            // if it is greater than or equal to the borrrowed amount, set borrowed amount to zero
            // and send collateral back to msg.msg.sender
            userToLoanInfo[msg.sender].borrowedAmount = 0;
            SafeERC20.safeTransfer(
                oracle.lendToken(),
                msg.sender,
                userToLoanInfo[msg.sender].collateralBalance
            );
        }
    }
}
