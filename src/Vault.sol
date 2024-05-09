// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import "./interfaces/IVault.sol";
import "./interfaces/eigenlayer/IDelegationManager.sol";
import "./interfaces/eigenlayer/IStrategyManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import {Test, console} from "forge-std/Test.sol";

/**
 * @title Vault
 * @author Aroon Kessani.
 * @notice : https://gist.github.com/arseneeth/052e1699755b2044439e2c7b3ce51673
 * @notice  This is the contract for Test task from DAOISM SYSTEMs . The main functionalities of this contract are
 * - User can deposit STETH in EigenLayer's strategy
 * - Owner can delegate Stakes to operator of its choice (a given owner can only delegate to a single operator at a time)
 * - Owner can undelegate assets from the operator it is delegated to (performed as part of the withdrawal process initiated)
 * - Owner can withdraw assets from eigner layer to this contract once queqed withdrawal duration is completed
 */
contract Vault is IVault, ERC20, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // Total Value Locked (TVL) deposited in eigenLayer
    uint256 TVL;

    // precision for deposits 
    uint256 constant PRECISION_NUMBER = 100;

    // Address of STETH token
    address constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    
    // Address of EigenLayer Strategy Manager
    address constant EIGENLAYER_STRATEGY_MANAGER = 0x858646372CC42E1A627fcE94aa7A7033e7CF075A;
    
    // Address of EigenLayer Delegation Manager
    address constant EIGENLAYER_DELEGATION_MANAGER = 0x39053D51B77DC0d36036Fc1fCc8Cb819df8Ef37A;
    
    // Address of the strategy contract
    address constant STRATEGY = 0x93c4b944D05dfe6df7645A86cd2206016c51564D;

    // Constructor to initialize the ERC20 token and set the owner
    constructor(address _owner) ERC20("RST", "RST") Ownable(_owner) {
        if (_owner == address(0)) revert ZeroAddress();
    }

    /**
     * @notice Deposit STETH into the vault
     * @param depositAmount The amount of STETH to deposit
     */
    function deposit(uint256 depositAmount) external override whenNotPaused nonReentrant {
        // Validate the deposit amount
        if (depositAmount == 0) {
            revert InvalidAmountToDeposit();
        }
        
        // Transfer STETH tokens from user to the contract
        IERC20(STETH).safeTransferFrom(msg.sender, address(this), depositAmount);
        
        // Calculate shares for the user
        uint256 shares = calculateShareAmount(depositAmount);
        
        // Deposit assets into the strategy
        _depositAssetIntoStrategy(IERC20(STETH).balanceOf(address(this)));
        
        // Update Total Value Locked (TVL)
        TVL += depositAmount;

        // Mint shares for the user
        _mint(msg.sender, shares);
    }

    /**
     * @notice Delegate stakes to a specified operator
     * @param operator Address of the operator to delegate stakes to
     * @param approverSignatureAndExpiry Signature and expiry for approval
     * @param approverSalt Salt for approval
     */
    function delegateTo(
        address operator,
        ISignatureUtils.SignatureWithExpiry memory approverSignatureAndExpiry,
        bytes32 approverSalt
    ) external override onlyOwner {
        
        // Contract can have STETH if withdrawToContract called so deposit before delegation to new operator
        if (IERC20(STETH).balanceOf(address(this)) > PRECISION_NUMBER)
            _depositAssetIntoStrategy(IERC20(STETH).balanceOf(address(this)));
        
        // Delegate stakes to the specified operator
        IDelegationManager(EIGENLAYER_DELEGATION_MANAGER).delegateTo(operator, approverSignatureAndExpiry, approverSalt);
    }

    /**
     * @notice Undelegate assets from the current operator
     */
    function undelegate() external override onlyOwner {
        // Undelegate assets from the current operator
        IDelegationManager(EIGENLAYER_DELEGATION_MANAGER).undelegate(address(this));
    }

    /**
     * @notice Withdraw assets from EigenLayer to this contract
     * @param withdrawal Withdrawal data
     */
    function withdrawToContract(IDelegationManager.Withdrawal calldata withdrawal) external override onlyOwner {
        // Define array for tokens
        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = IStrategy(STRATEGY).underlyingToken();
        
        // Complete queued withdrawal
        IDelegationManager(EIGENLAYER_DELEGATION_MANAGER).completeQueuedWithdrawal(withdrawal, tokens, 0, true);
        
    }

    /**
     * @notice Pause the vault
     */
    function pauseVault() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the vault
     */
    function unpauseVault() external override onlyOwner {
        _unpause();
    }

    /**
     * @notice Calculate shares based on the deposited amount
     * @param amount The amount of STETH deposited
     * @return The calculated shares
     */
    function calculateShareAmount(uint256 amount) public view returns (uint256) {
        uint256 supply = totalSupply();
        return supply == 0 ? amount : Math.mulDiv(amount, supply, TVL);
    }

    /**
     * @notice Deposit STETH assets into the strategy
     * @param depositAmount The amount of STETH to deposit
     */
    function _depositAssetIntoStrategy(uint256 depositAmount) internal {
        // Approve STETH transfer to strategy manager
        IERC20(STETH).approve(EIGENLAYER_STRATEGY_MANAGER, depositAmount);
        
        // Deposit assets into the strategy
        IStrategyManager(EIGENLAYER_STRATEGY_MANAGER).depositIntoStrategy(IStrategy(STRATEGY), IERC20(STETH), depositAmount);
    }
}
