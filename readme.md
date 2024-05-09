# Vault Contract

---

## Overview

The Vault Contract facilitates the management of STETH (a token) in EigenLayer's strategy. It enables users to deposit STETH into the vault, delegate stakes to a specified operator, undelegate assets from the current operator, and withdraw assets from EigenLayer to this contract. This README provides an overview of the contract's functionality, usage instructions, and key considerations.

## Functionality

### 1. Deposit
- Allows users to deposit STETH tokens into the vault.
- Calculates and mints shares for the user based on the deposited amount.
- Deposits the assets into EigenLayer's strategy.

### 2. Delegate Stakes
- Enables the owner to delegate stakes to a specified operator.
- Handles depositing STETH before delegation if needed.

### 3. Undelegate Assets
- Allows the owner to undelegate assets from the current operator.

### 4. Withdraw Assets
- Facilitates withdrawing assets from EigenLayer to this contract.
- Completes queued withdrawals and transfers assets to the contract.

### 5. Pause/Unpause Vault
- Provides functionality to pause and unpause the vault contract.

## Usage Instructions

To interact with the Vault Contract:

1. **Deposit STETH:** Call the `deposit` function with the desired deposit amount.
2. **Delegate Stakes:** Use the `delegateTo` function to delegate stakes to a specified operator.
3. **Undelegate Assets:** Call the `undelegate` function to undelegate assets from the current operator.
4. **Withdraw Assets:** Utilize the `withdrawToContract` function to withdraw assets from EigenLayer to this contract.
5. **Pause/Unpause:** Use the `pauseVault` and `unpauseVault` functions to pause and unpause the vault contract respectively.



## Cloning and Setup

1. **Clone Repository:** Clone the repository containing the contract source code:
  ```
  git clone repo-url
  ```
2. **Navigate to Project Directory:** Change into the project directory:
  ```
  cd Test-Task
  ```
3. **Build Contract:** Build the contract using Forge:
  ```
  forge build
  ```
4. **Test Contract with Mainnet Forking:**
  ```
  forge test --rpc-url http://127.0.0.1:8545/ --match-path test/Vault.t.sol
  ```
- Keep the old terminal running.

5. **Run Tests:**
- Open another new bash terminal.
- Run tests with RPC URL and match path:
  ```
  forge test --rpc-url http://127.0.0.1:8545/ --match-path test/Vault.t.sol
  ```


