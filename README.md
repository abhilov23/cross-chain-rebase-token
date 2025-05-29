Cross-Chain Rebase Token
The Cross-Chain Rebase Token protocol enables users to deposit assets into a vault and receive rebase tokens that represent their underlying balance. These tokens are designed to dynamically adjust their balance over time, facilitating cross-chain transfers between ZKSync Sepolia and Ethereum Sepolia testnets using Chainlink's Cross-Chain Interoperability Protocol (CCIP). The protocol incentivizes early adopters with a decreasing global interest rate and rewards user interactions.
Protocol Overview

Vault Deposits:

Users deposit assets into a vault and receive rebase tokens that reflect their underlying balance.
The vault, deployed on Ethereum Sepolia, manages deposited assets.


Rebase Token:

The balanceOf function dynamically shows a user's token balance, which increases linearly with time.
Tokens are minted for users when they perform actions such as minting, burning, transferring, or bridging tokens across chains.
This incentivizes active participation and increases token adoption.


Interest Rate:

Each user is assigned an individual interest rate based on the protocol's global interest rate at the time of their deposit into the vault.
The global interest rate can only decrease over time to reward early adopters.
This mechanism encourages early participation and long-term engagement with the protocol.



Contracts

RebaseToken: An ERC-20 token with rebasing capabilities, supporting dynamic balance adjustments and mint/burn operations for cross-chain transfers.
RebaseTokenPool: Manages token locking/burning on the source chain and minting/releasing on the destination chain, integrated with Chainlink CCIP.
Vault: Handles user deposits on Ethereum Sepolia, issuing rebase tokens to represent the deposited balance.

Prerequisites
Ensure you have the following installed:

Foundry: For compiling and deploying contracts. Install with:curl -L https://foundry.paradigm.xyz | bash
foundryup


Git: To clone the repository.
Node.js: Optional, for additional tooling or testing.
Environment Variables: An Alchemy API key and a funded private key for both ZKSync Sepolia and Ethereum Sepolia testnets.

Setup

Clone the Repository:
git clone https://github.com/abhilov23/cross-chain-rebase-token.git
cd cross-chain-rebase-token


Install Dependencies:Install Foundry dependencies:
forge install


Configure Environment Variables:Create a .env file in the root directory with the following:
ZKSYNC_SEPOLIA_RPC_URL=https://zksync-sepolia.g.alchemy.com/v2/<your-alchemy-api-key>
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/<your-alchemy-api-key>
ABHILOV_PRIVATE_KEY=<your-private-key>

Replace <your-alchemy-api-key> with your Alchemy API key and <your-private-key> with a funded private key for both networks.
Load the environment variables:
source .env


Verify Contract Source Files:Ensure the following files are in the src/ directory:

RebaseToken.sol
RebaseTokenPool.sol
Vault.sol



Deployment
The deploy_contracts.sh script deploys the RebaseToken, RebaseTokenPool, and Vault contracts to ZKSync Sepolia and Ethereum Sepolia testnets.
Steps

Build Contracts:Compile the contracts:
forge build


Run the Deployment Script:Execute the deployment script:
chmod +x deploy_contracts.sh
./deploy_contracts.sh


Output:The script outputs the deployed contract addresses and deployer address:
Deployer address: <deployer-address>
ZKSync RebaseToken deployed at: <zksync-rebase-token-address>
ZKSync Pool deployed at: <zksync-pool-address>
Sepolia RebaseToken deployed at: <sepolia-rebase-token-address>
Sepolia Pool deployed at: <sepolia-pool-address>
Vault deployed at: <vault-address>



Notes

The script uses the --legacy flag for ZKSync deployments to ensure compatibility with its transaction format.
Ensure the deployer account has sufficient ETH on both networks.
The RebaseTokenPool constructor requires a token address (generated during deployment), an empty array ([]), an RMN proxy address, and a router address, which are hardcoded in the script.

Project Structure
cross-chain-rebase-token/
├── src/
│   ├── RebaseToken.sol        # Rebase token contract
│   ├── RebaseTokenPool.sol    # Cross-chain pool contract
│   ├── Vault.sol              # Vault contract for deposits
├── deploy_contracts.sh        # Deployment script
├── .env.example               # Example environment file
├── README.md                  # This file

Post-Deployment
After deployment, you may need to:

Configure Contracts: Set roles (e.g., mint/burn permissions) and chain mappings for cross-chain functionality using functions like grantMintAndBurnRole and applyChainUpdates.
Test Cross-Chain Transfers: Use Chainlink CCIP to bridge tokens between ZKSync and Sepolia.
Verify Contracts: Verify the deployed contracts on block explorers like ZKSync Explorer or Etherscan.

Troubleshooting

Deployment Fails:
Check if the private key has sufficient ETH on both networks.
Verify RPC URLs are active and correct.
Run forge build to check for compilation errors.


ZKSync Compatibility: The --legacy flag is used for ZKSync; remove it if ZKSync updates its transaction format.

Contributing
Contributions are welcome! Please:

Fork the repository.
Create a feature branch (git checkout -b feature/your-feature).
Commit changes (git commit -m "Add your feature").
Push to the branch (git push origin feature/your-feature).
Open a pull request.

License
This project is licensed under the MIT License. See the LICENSE file for details.
Contact
For questions or support, open an issue on the GitHub repository or contact the maintainer at [your-email@example.com].
