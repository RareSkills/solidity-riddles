// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interface/IAMMOracle.sol";
import {TransferHelper, AMM} from "./AMM.sol";

// contract Lender {
//     address public owner;
//     address public borrower;
//     IAMMOracle Oracle;
//     IERC20 public immutable lendToken;
//     uint lastDesiredEthAmount;
//     uint lastPriceRatioForDesiredEthAmount;

//     mapping(address => uint) depositedEtherBalance;
//     mapping(address => uint) borrowedEtherBalance;
//     mapping(address => uint) lendTokenCollateralBalance;

//     constructor(address _Oracle, address _lendToken) {
//         Oracle = IAMMOracle(_Oracle);
//         lendToken = IERC20(_lendToken);
//         owner = msg.sender;
//     }

//     function depositEther(uint amount) external payable {
//         require(msg.sender == owner);

//         require(msg.value == amount);
//         depositedEtherBalance[msg.sender] += amount;
//     }

//     function borrowEther(uint desiredAMount) external {
//         require(desiredAMount <= address(this).balance);

//         uint collateralAmountToPay = Oracle.getEthToLendTokenPrice(
//             desiredAMount
//         );

//         require(
//             lendToken.transferFrom(
//                 msg.sender,
//                 address(this),
//                 collateralAmountToPay
//             )
//         );

//         borrowedEtherBalance[msg.sender] += desiredAMount;
//         lendTokenCollateralBalance[msg.sender] += collateralAmountToPay;
//         lastDesiredEthAmount = desiredAMount;
//         lastPriceRatioForDesiredEthAmount = collateralAmountToPay;
//         borrower = msg.sender;

//         payable(msg.sender).transfer(desiredAMount);
//     }

//     function withdrawDeposit() external {
//         require(msg.sender == owner);
//         uint balance = depositedEtherBalance[msg.sender];

//         require(balance > 0, "No deposited balance");

//         require(
//             address(this).balance >= balance,
//             "Not enough ether in contract"
//         );
//         depositedEtherBalance[msg.sender] = 0;

//         payable(msg.sender).transfer(balance);
//     }

//     function repayLoan() external payable {
//         uint amountToRepay = borrowedEtherBalance[msg.sender];
//         uint collateralBalance = lendTokenCollateralBalance[msg.sender];

//         require(
//             msg.value == amountToRepay,
//             "Send required amount to repay loan"
//         );

//         borrowedEtherBalance[msg.sender] = 0;

//         lendTokenCollateralBalance[msg.sender] = 0;

//         require(lendToken.transfer(msg.sender, collateralBalance));
//     }

//     function liquidateCollateral()
//         external
//         returns (uint currentPriceRatioForDesiredEthAmount)
//     {
//         require(msg.sender == owner);

//         currentPriceRatioForDesiredEthAmount = Oracle.getEthToLendTokenPrice(
//             lastDesiredEthAmount
//         );

//         if (
//             currentPriceRatioForDesiredEthAmount >
//             lastPriceRatioForDesiredEthAmount
//         ) {
//             uint borrowerLendTokenBalance = lendTokenCollateralBalance[
//                 borrower
//             ];
//             lendTokenCollateralBalance[borrower] = 0;

//             lendToken.transfer(owner, borrowerLendTokenBalance);
//         }
//     }

//     receive() external payable {}
// }

contract Lender {
    AMM immutable oracle;
    address immutable lender;

    // important to avoid division/modulo by 0 panic errors
    uint16 private constant collateralContext = 1_000;
    uint16 private constant overcollateralizationMultiplier = 2_000;
    uint16 private constant liquidationThreshold = 1_500;

    struct LoanInfo {
        uint256 collateralBalance;
        uint256 borrowedAmount;
    }

    mapping(address => LoanInfo) userToLoanInfo;

    constructor(address _oracle) {
        oracle = AMM(_oracle);
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
        require(loanInfo.borrowedAmount > 0, "Nothing to liquidate");

        uint256 lendQuote = (oracle.lendTokenReserve() *
            loanInfo.borrowedAmount) / oracle.ethReserve();

        uint256 collateralRequired = (lendQuote * liquidationThreshold) /
            collateralContext;

        require(
            loanInfo.collateralBalance >= collateralRequired,
            "Not undercollaterized"
        );

        // transfer owed amount to liquidator (msg.sender)
        TransferHelper.safeTransfer(
            address(oracle.lendToken()),
            msg.sender,
            lendQuote
        );

        // transfer left overs to borrower if any
        if (loanInfo.collateralBalance - lendQuote > 0) {
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
