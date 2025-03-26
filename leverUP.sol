pragma solidity ^0.6.12;

import {FlashLoanReceiverBase} from "@aave/protocol-v2/contracts/flashloan/base/FlashLoanReceiverBase.sol";
import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import {ILendingPoolAddressesProvider} from "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import {IERC20} from "@aave/protocol-v2/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

contract AaveFlashLoanDepositBorrow is FlashLoanReceiverBase {
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // Mainnet DAI
    uint256 public constant INITIAL_DEPOSIT = 30 ether; // $30 in DAI (assuming 18 decimals)
    uint256 public constant FLASH_LOAN_AMOUNT = 70 ether; // $70 in DAI
    uint256 public constant TOTAL_DEPOSIT = 100 ether; // $100 in DAI
    uint256 public constant BORROW_AMOUNT = 70 ether; // $70 in DAI
    address public owner;

    constructor(address _addressProvider) FlashLoanReceiverBase(_addressProvider) public {
        owner = msg.sender;
    }

    // Function to initiate the flash loan and execute the strategy
    function executeStrategy() external {
        require(msg.sender == owner, "Only owner");
        require(IERC20(DAI).balanceOf(address(this)) >= INITIAL_DEPOSIT, "Insufficient DAI balance");

        // Request flash loan of $70 DAI
        address[] memory assets = new address[](1);
        assets[0] = DAI;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = FLASH_LOAN_AMOUNT;
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0; // 0 = no debt (must repay flash loan)

        bytes memory params = "";
        LENDING_POOL.flashLoan(
            address(this), // Receiver of the flash loan
            assets,
            amounts,
            modes,
            address(this), // onBehalfOf (this contract will manage the debt)
            params,
            0 // Referral code
        );
    }

    // Callback function executed by Aave after receiving the flash loan
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(msg.sender == address(LENDING_POOL), "Caller must be LendingPool");
        require(assets[0] == DAI, "Invalid asset");
        require(amounts[0] == FLASH_LOAN_AMOUNT, "Invalid flash loan amount");

        // Step 1: Approve LendingPool to spend contract's DAI ($30) and flash loaned DAI ($70)
        IERC20(DAI).approve(address(LENDING_POOL), TOTAL_DEPOSIT);

        // Step 2: Deposit $100 DAI ($30 from contract + $70 from flash loan) into Aave
        LENDING_POOL.deposit(DAI, TOTAL_DEPOSIT, address(this), 0);

        // Step 3: Borrow $70 DAI from Aave against the deposited collateral
        LENDING_POOL.borrow(DAI, BORROW_AMOUNT, 2, 0, address(this)); // 2 = variable rate

        // Step 4: Calculate amount owed for flash loan ($70 + 0.09% fee)
        uint256 amountOwing = amounts[0] + premiums[0]; // $70 + $0.063

        // Step 5: Approve LendingPool to pull the flash loan repayment
        IERC20(DAI).approve(address(LENDING_POOL), amountOwing);

        // Flash loan is repaid automatically by Aave pulling the funds
        return true;
    }

    // Function to deposit initial DAI into the contract
    function fundContract(uint256 amount) external {
        require(msg.sender == owner, "Only owner");
        require(IERC20(DAI).transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }

    // Withdraw any remaining DAI (for cleanup)
    function withdrawDAI() external {
        require(msg.sender == owner, "Only owner");
        uint256 balance = IERC20(DAI).balanceOf(address(this));
        require(IERC20(DAI).transfer(owner, balance), "Transfer failed");
    }

    // Receive ETH (if any)
    receive() external payable {}
}
