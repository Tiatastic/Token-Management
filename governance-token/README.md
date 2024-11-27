# Advanced Fungible Token (AFT) for Stacks smart contract

## Overview

This is a robust and feature-rich token contract implemented in Clarity for the Stacks blockchain. The contract provides advanced functionality for token management, including transfers, approvals, minting, burning, and administrative controls.

## Features

- **Token Initialization**: Customize token name, symbol, and decimal places
- **Transfer Mechanisms**: 
  - Direct token transfers
  - Approved third-party transfers
- **Balance Management**: 
  - Check token balances
  - Track spending allowances
- **Administrative Controls**:
  - Token minting
  - Token burning
  - Address blacklisting
  - Contract pause functionality
- **Metadata Support**: Set and manage token metadata

## Error Handling

The contract includes comprehensive error handling with specific error codes:
- `ERR_OWNER_ONLY` (u100): Unauthorized owner access
- `ERR_NOT_TOKEN_OWNER` (u101): Operation restricted to token owner
- `ERR_INSUFFICIENT_BALANCE` (u102): Insufficient token balance
- `ERR_INVALID_AMOUNT` (u103): Invalid token amount
- `ERR_BLACKLISTED` (u104): Blacklisted address
- `ERR_CONTRACT_PAUSED` (u105): Contract is currently paused

## Key Functions

### Read Functions
- `get-token-name()`: Retrieve token display name
- `get-token-symbol()`: Get token trading symbol
- `get-token-decimals()`: Get decimal places
- `get-token-total-supply()`: Check total token supply
- `get-holder-balance(wallet-address)`: Check balance of a specific address
- `get-spending-allowance(owner, spender)`: Check approved spending amount

### Write Functions
- `initialize-token(name, symbol, decimals)`: Set up token parameters
- `transfer-tokens(recipient, amount)`: Transfer tokens
- `transfer-tokens-from(owner, recipient, amount)`: Transfer tokens on behalf of owner
- `approve-token-spender(spender, amount)`: Approve token spending
- `mint-new-tokens(recipient, amount)`: Mint new tokens
- `burn-existing-tokens(amount)`: Burn tokens
- `add-address-to-blacklist(address)`: Blacklist an address
- `remove-address-from-blacklist(address)`: Remove address from blacklist
- `set-token-metadata(token-id, name, description, uri)`: Set token metadata

## Security Features

- Owner-only administrative functions
- Blacklist mechanism to prevent transfers from/to specific addresses
- Transfer validation checks
- Spending allowance mechanism
- Contract pause functionality

## Usage Example

```clarity
;; Initialize token
(initialize-token "My Cool Token" "MCT" u6)

;; Mint tokens to an address
(mint-new-tokens 'ST1234... u1000000)

;; Transfer tokens
(transfer-tokens 'ST5678... u500)

;; Approve a spender
(approve-token-spender 'ST9012... u250)
```