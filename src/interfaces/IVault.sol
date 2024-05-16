// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;
import "./eigenlayer/ISignatureUtils.sol";
import "./eigenlayer/IDelegationManager.sol";
interface IVault {
    
    error ZeroAddress();
    error InvalidAmountToDeposit();
    error InvalidPriceValue(int256 price);
    


    struct SignatureWithExpiry {
        // the signature itself, formatted as a single bytes object
        bytes signature;
        // the expiration timestamp (UTC) of the signature
        uint256 expiry;
    }

    function deposit(uint256 depositAmount) external;

    function delegateTo(address operator,
        ISignatureUtils.SignatureWithExpiry memory approverSignatureAndExpiry,
        bytes32 approverSalt) external;

    function undelegate() external;

    function withdrawToContract(
        IDelegationManager.Withdrawal calldata withdrawal
    ) external;

    function pauseVault() external;
    
    function unpauseVault() external;
}