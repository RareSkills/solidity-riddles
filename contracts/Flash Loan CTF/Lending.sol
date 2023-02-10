// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interface/IAMMOracle.sol";
import  "./AMM.sol";
import "./library/TransferHelper.sol";

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

    constructor(address _oracle) {
        oracle = AMM(payable(_oracle));
        lender = msg.sender;
    }

    // assume this is a private pool where only one address can provide LP
    // can be solved using shares msg.value as sqrt(k)
    function addLiquidity() external payable {}

    function removeLiquidity(uint256 amount) external {
        require(msg.sender == lender, "UNAUTHORIZED");
        require(amount >= address(this).balance, "Insufficient balance");

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

        // overcollaterize using overcollateralizationMultiplier
        lendTokenCollateral =
            (lendQuote * overcollateralizationMultiplier) /
            collateralContext;

        // update storage
        userToLoanInfo[msg.sender] = LoanInfo({
            collateralBalance: lendTokenCollateral,
            borrowedAmount: ethAmount
        });

        // transfer collateral in
        TransferHelper.safeTransferFrom(
            address(oracle.lendToken()),
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
        TransferHelper.safeTransfer(address(token), msg.sender, amount);

        // transfer left overs to borrower if any
        if (loanInfo.collateralBalance != amount) {
            TransferHelper.safeTransfer(
                address(oracle.lendToken()),
                msg.sender,
                loanInfo.collateralBalance - lendQuote
            );
        }
    }

    receive() external payable {
        if (msg.value < userToLoanInfo[msg.sender].borrowedAmount) {
            userToLoanInfo[msg.sender].borrowedAmount -= msg.value;
        } else {
            userToLoanInfo[msg.sender].borrowedAmount = 0;
            TransferHelper.safeTransfer(
                address(oracle.lendToken()),
                msg.sender,
                userToLoanInfo[msg.sender].collateralBalance
            );
        }
    }
}
