# 🌐 Cross-Chain Rebase Token

The **Cross-Chain Rebase Token** protocol enables users to deposit assets into a vault and receive rebase tokens that represent their underlying balance. These tokens are designed to dynamically adjust their balance over time and facilitate cross-chain transfers between **ZKSync Sepolia** and **Ethereum Sepolia** testnets using **Chainlink's Cross-Chain Interoperability Protocol (CCIP)**.

The protocol incentivizes early adopters with a decreasing global interest rate and rewards user interactions.

---

## 📖 Protocol Overview

### 🔐 Vault Deposits
- Users deposit assets into a vault and receive rebase tokens that reflect their underlying balance.
- The vault, deployed on **Ethereum Sepolia**, manages deposited assets.

### 🪙 Rebase Token
- The `balanceOf` function dynamically shows a user's token balance, which increases **linearly over time**.
- Tokens are minted when users **mint**, **burn**, **transfer**, or **bridge** tokens across chains.
- This design **incentivizes active participation** and increases token adoption.

### 📈 Interest Rate
- Each user is assigned an **individual interest rate** based on the **global interest rate** at the time of deposit.
- The global interest rate can **only decrease** over time to reward early adopters.
- This mechanism encourages **early participation and long-term engagement** with the protocol.

---

## 🧱 Contracts

| Contract          | Description |
|------------------|-------------|
| `RebaseToken`     | ERC-20 token with rebasing capabilities, supporting dynamic balance updates and mint/burn operations. |
| `RebaseTokenPool` | Manages token locking/burning on the source chain and minting/releasing on the destination chain using Chainlink CCIP. |
| `Vault`           | Handles user deposits on Ethereum Sepolia and issues rebase tokens to represent balances. |

---
