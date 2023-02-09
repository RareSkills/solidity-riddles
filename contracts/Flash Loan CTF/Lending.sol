// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interface/IAMMOracle.sol";

contract Lender {
    address public owner;
    address public borrower;
    IAMMOracle Oracle;
    IERC20 public immutable lendToken;
    uint lastDesiredEthAmount;
    uint lastPriceRatioForDesiredEthAmount;

    mapping(address => uint) depositedEtherBalance;
    mapping(address => uint) borrowedEtherBalance;
    mapping(address => uint) lendTokenCollateralBalance;

    constructor(address _Oracle, address _lendToken) {
        Oracle = IAMMOracle(_Oracle);
        lendToken = IERC20(_lendToken);
        owner = msg.sender;
    }

    function depositEther(uint amount) external payable {
        require(msg.sender == owner);

        require(msg.value == amount);
        depositedEtherBalance[msg.sender] += amount;
    }

    function borrowEther(uint desiredAMount) external {
        require(desiredAMount <= address(this).balance);

        uint collateralAmountToPay = Oracle.getEthToLendTokenPrice(
            desiredAMount
        );

        require(
            lendToken.transferFrom(
                msg.sender,
                address(this),
                collateralAmountToPay
            )
        );

        borrowedEtherBalance[msg.sender] += desiredAMount;
        lendTokenCollateralBalance[msg.sender] += collateralAmountToPay;
        lastDesiredEthAmount = desiredAMount;
        lastPriceRatioForDesiredEthAmount = collateralAmountToPay;
        borrower = msg.sender;

        payable(msg.sender).transfer(desiredAMount);
    }

    function withdrawDeposit() external {
        require(msg.sender == owner);
        uint balance = depositedEtherBalance[msg.sender];

        require(balance > 0, "No deposited balance");

        require(
            address(this).balance >= balance,
            "Not enough ether in contract"
        );
        depositedEtherBalance[msg.sender] = 0;

        payable(msg.sender).transfer(balance);
    }

    function repayLoan() external payable {
        uint amountToRepay = borrowedEtherBalance[msg.sender];
        uint collateralBalance = lendTokenCollateralBalance[msg.sender];

        require(
            msg.value == amountToRepay,
            "Send required amount to repay loan"
        );

        borrowedEtherBalance[msg.sender] = 0;

        lendTokenCollateralBalance[msg.sender] = 0;

        require(lendToken.transfer(msg.sender, collateralBalance));
    }

    function liquidateCollateral()
        external
        returns (uint currentPriceRatioForDesiredEthAmount)
    {
        require(msg.sender == owner);

        currentPriceRatioForDesiredEthAmount = Oracle.getEthToLendTokenPrice(
            lastDesiredEthAmount
        );

        if (
            currentPriceRatioForDesiredEthAmount >
            lastPriceRatioForDesiredEthAmount
        ) {
            uint borrowerLendTokenBalance = lendTokenCollateralBalance[
                borrower
            ];
            lendTokenCollateralBalance[borrower] = 0;

            lendToken.transfer(owner, borrowerLendTokenBalance);
        }
    }

    receive() external payable {}
}
