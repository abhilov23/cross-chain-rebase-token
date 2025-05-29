#!/bin/bash
set -e  # Exit on error

# Constants
AMOUNT=100000000000000000000  # 100 tokens with 18 decimals

DEFAULT_ZKSYNC_LOCAL_KEY="0x7726827caac94a7f9e1b160f7ea819f172f7b6f9d2a97f992c38edeab82d4110"
DEFAULT_ZKSYNC_ADDRESS="0x36615Cf349d7F6344891B1e7CA7C72883F5dc049"

# ZKSync Addresses
ZKSYNC_REGISTRY_MODULE_OWNER_CUSTOM="0x3139687Ee9938422F57933C3CDB3E21EE43c4d0F"
ZKSYNC_TOKEN_ADMIN_REGISTRY="0xc7777f12258014866c677Bdb679D0b007405b7DF"
ZKSYNC_ROUTER="0xA1fdA8aa9A8C4b945C45aD30647b01f07D7A0B16"
ZKSYNC_RNM_PROXY_ADDRESS="0x3DA20FD3D8a8f8c1f1A5fD03648147143608C467"
ZKSYNC_SEPOLIA_CHAIN_SELECTOR="6898391096552792247"
ZKSYNC_LINK_ADDRESS="0x23A1aFD896c8c8876AF46aDc38521f4432658d1e"

# Sepolia Addresses
SEPOLIA_REGISTRY_MODULE_OWNER_CUSTOM="0x62e731218d0D47305aba2BE3751E7EE9E5520790"
SEPOLIA_TOKEN_ADMIN_REGISTRY="0x95F29FEE11c5C55d26cCcf1DB6772DE953B37B82"
SEPOLIA_ROUTER="0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59"
SEPOLIA_RNM_PROXY_ADDRESS="0xba3f6251de62dED61Ff98590cB2fDf6871FbB991"
SEPOLIA_CHAIN_SELECTOR="16015286601757825753"
SEPOLIA_LINK_ADDRESS="0x779877A7B0D9E8603169DdbD7836e478b4624789"

# Environment variables
ZKSYNC_SEPOLIA_RPC_URL="https://zksync-sepolia.g.alchemy.com/v2/dgU6UCCmiNDhcgnkxZS5D1Nw1WafZLZD"
SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/dgU6UCCmiNDhcgnkxZS5D1Nw1WafZLZD"
ABHILOV_PRIVATE_KEY="0x8e58cee3a2b395d1dd0ac34e212e812936f79a96c7bc7456c3217ba88882f427"

# Get deployer address
DEPLOYER_ADDRESS=$(cast wallet address --private-key "${ABHILOV_PRIVATE_KEY}")
echo "Deployer address: $DEPLOYER_ADDRESS"

# Build contracts
echo "Building contracts..."
forge build

echo "=== DEPLOYING ON ZKSYNC ==="

echo "Deploying RebaseToken on ZKSync..."
DEPLOY_OUTPUT=$(forge create src/RebaseToken.sol:RebaseToken \
    --rpc-url "${ZKSYNC_SEPOLIA_RPC_URL}" \
    --private-key "${ABHILOV_PRIVATE_KEY}" \
    --legacy \
    --broadcast)

ZKSYNC_REBASE_TOKEN_ADDRESS=$(echo "$DEPLOY_OUTPUT" | awk '/Deployed to:/ {print $3}')

if [ -z "$ZKSYNC_REBASE_TOKEN_ADDRESS" ]; then
    echo "Error: Failed to deploy RebaseToken on ZKSync"
    echo "Deploy output: $DEPLOY_OUTPUT"
    exit 1
fi

echo "ZKSync RebaseToken deployed at: $ZKSYNC_REBASE_TOKEN_ADDRESS"

echo "Deploying RebaseTokenPool on ZKSync..."
POOL_DEPLOY_OUTPUT=$(forge create src/RebaseTokenPool.sol:RebaseTokenPool \
    --rpc-url "${ZKSYNC_SEPOLIA_RPC_URL}" \
    --private-key "${ABHILOV_PRIVATE_KEY}" \
    --legacy \
    --constructor-args "${ZKSYNC_REBASE_TOKEN_ADDRESS}" "[]" "${ZKSYNC_RNM_PROXY_ADDRESS}" "${ZKSYNC_ROUTER}" \
    --broadcast)

ZKSYNC_POOL_ADDRESS=$(echo "$POOL_DEPLOY_OUTPUT" | awk '/Deployed to:/ {print $3}')

if [ -z "$ZKSYNC_POOL_ADDRESS" ]; then
    echo "Error: Failed to deploy RebaseTokenPool on ZKSync"
    echo "Deploy output: $POOL_DEPLOY_OUTPUT"
    exit 1
fi

echo "ZKSync Pool deployed at: $ZKSYNC_POOL_ADDRESS"

echo "Setting mint/burn role on ZKSync..."
cast send "${ZKSYNC_REBASE_TOKEN_ADDRESS}" \
    "grantMintAndBurnRole(address)" "${ZKSYNC_POOL_ADDRESS}" \
    --rpc-url "${ZKSYNC_SEPOLIA_RPC_URL}" \
    --private-key "${ABHILOV_PRIVATE_KEY}"

echo "Setting CCIP roles on ZKSync..."
cast send "${ZKSYNC_REGISTRY_MODULE_OWNER_CUSTOM}" \
    "registerAdminViaOwner(address)" "${ZKSYNC_REBASE_TOKEN_ADDRESS}" \
    --rpc-url "${ZKSYNC_SEPOLIA_RPC_URL}" \
    --private-key "${ABHILOV_PRIVATE_KEY}"

cast send "${ZKSYNC_TOKEN_ADMIN_REGISTRY}" \
    "acceptAdminRole(address)" "${ZKSYNC_REBASE_TOKEN_ADDRESS}" \
    --rpc-url "${ZKSYNC_SEPOLIA_RPC_URL}" \
    --private-key "${ABHILOV_PRIVATE_KEY}"

cast send "${ZKSYNC_TOKEN_ADMIN_REGISTRY}" \
    "setPool(address,address)" "${ZKSYNC_REBASE_TOKEN_ADDRESS}" "${ZKSYNC_POOL_ADDRESS}" \
    --rpc-url "${ZKSYNC_SEPOLIA_RPC_URL}" \
    --private-key "${ABHILOV_PRIVATE_KEY}"

echo "=== DEPLOYING ON SEPOLIA ==="

echo "Deploying RebaseToken on Sepolia..."
SEPOLIA_DEPLOY_OUTPUT=$(forge create src/RebaseToken.sol:RebaseToken \
    --rpc-url "${SEPOLIA_RPC_URL}" \
    --private-key "${ABHILOV_PRIVATE_KEY}" \
    --broadcast)

SEPOLIA_REBASE_TOKEN_ADDRESS=$(echo "$SEPOLIA_DEPLOY_OUTPUT" | awk '/Deployed to:/ {print $3}')

if [ -z "$SEPOLIA_REBASE_TOKEN_ADDRESS" ]; then
    echo "Error: Failed to deploy RebaseToken on Sepolia"
    exit 1
fi

echo "Sepolia RebaseToken deployed at: $SEPOLIA_REBASE_TOKEN_ADDRESS"

echo "Deploying RebaseTokenPool on Sepolia..."
SEPOLIA_POOL_DEPLOY_OUTPUT=$(forge create src/RebaseTokenPool.sol:RebaseTokenPool \
    --rpc-url "${SEPOLIA_RPC_URL}" \
    --private-key "${ABHILOV_PRIVATE_KEY}" \
    --constructor-args "${SEPOLIA_REBASE_TOKEN_ADDRESS}" "[]" "${SEPOLIA_RNM_PROXY_ADDRESS}" "${SEPOLIA_ROUTER}" \
    --broadcast)

SEPOLIA_POOL_ADDRESS=$(echo "$SEPOLIA_POOL_DEPLOY_OUTPUT" | awk '/Deployed to:/ {print $3}')

if [ -z "$SEPOLIA_POOL_ADDRESS" ]; then
    echo "Error: Failed to deploy RebaseTokenPool on Sepolia"
    exit 1
fi

echo "Sepolia Pool deployed at: $SEPOLIA_POOL_ADDRESS"

echo "Setting mint/burn role on Sepolia..."
cast send "${SEPOLIA_REBASE_TOKEN_ADDRESS}" \
    "grantMintAndBurnRole(address)" "${SEPOLIA_POOL_ADDRESS}" \
    --rpc-url "${SEPOLIA_RPC_URL}" \
    --private-key "${ABHILOV_PRIVATE_KEY}"

echo "Setting CCIP roles on Sepolia..."
cast send "${SEPOLIA_REGISTRY_MODULE_OWNER_CUSTOM}" \
    "registerAdminViaOwner(address)" "${SEPOLIA_REBASE_TOKEN_ADDRESS}" \
    --rpc-url "${SEPOLIA_RPC_URL}" \
    --private-key "${ABHILOV_PRIVATE_KEY}"

cast send "${SEPOLIA_TOKEN_ADMIN_REGISTRY}" \
    "acceptAdminRole(address)" "${SEPOLIA_REBASE_TOKEN_ADDRESS}" \
    --rpc-url "${SEPOLIA_RPC_URL}" \
    --private-key "${ABHILOV_PRIVATE_KEY}"

cast send "${SEPOLIA_TOKEN_ADMIN_REGISTRY}" \
    "setPool(address,address)" "${SEPOLIA_REBASE_TOKEN_ADDRESS}" "${SEPOLIA_POOL_ADDRESS}" \
    --rpc-url "${SEPOLIA_RPC_URL}" \
    --private-key "${ABHILOV_PRIVATE_KEY}"

echo "=== DEPLOYING VAULT ==="

echo "Deploying Vault on Sepolia..."
VAULT_DEPLOY_OUTPUT=$(forge create src/Vault.sol:Vault \
    --rpc-url "${SEPOLIA_RPC_URL}" \
    --private-key "${ABHILOV_PRIVATE_KEY}" \
    --constructor-args "${SEPOLIA_REBASE_TOKEN_ADDRESS}" \
    --broadcast)

VAULT_ADDRESS=$(echo "$VAULT_DEPLOY_OUTPUT" | awk '/Deployed to:/ {print $3}')

if [ -z "$VAULT_ADDRESS" ]; then
    echo "Error: Failed to deploy Vault"
    exit 1
fi

echo "Vault deployed at: $VAULT_ADDRESS"

echo "Granting mint/burn role to Vault..."
cast send "${SEPOLIA_REBASE_TOKEN_ADDRESS}" \
    "grantMintAndBurnRole(address)" "${VAULT_ADDRESS}" \
    --rpc-url "${SEPOLIA_RPC_URL}" \
    --private-key "${ABHILOV_PRIVATE_KEY}"

echo "=== CONFIGURING POOLS ==="

echo "Configuring Sepolia pool for ZKSync..."
cast send "${SEPOLIA_POOL_ADDRESS}" \
    "applyChainUpdates(uint64[],(uint64,bytes[],bytes,(bool,uint128,uint128),(bool,uint128,uint128))[])" \
    "[${ZKSYNC_SEPOLIA_CHAIN_SELECTOR}]" \
    "[(${ZKSYNC_SEPOLIA_CHAIN_SELECTOR},[$(cast abi-encode 'f(address)' ${ZKSYNC_POOL_ADDRESS})],$(cast abi-encode 'f(address)' ${ZKSYNC_REBASE_TOKEN_ADDRESS}),(false,0,0),(false,0,0))]" \
    --rpc-url "${SEPOLIA_RPC_URL}" \
    --private-key "${ABHILOV_PRIVATE_KEY}"

echo "Configuring ZKSync pool for Sepolia..."
cast send "${ZKSYNC_POOL_ADDRESS}" \
    "applyChainUpdates(uint64[],(uint64,bytes[],bytes,(bool,uint128,uint128),(bool,uint128,uint128))[])" \
    "[${SEPOLIA_CHAIN_SELECTOR}]" \
    "[(${SEPOLIA_CHAIN_SELECTOR},[$(cast abi-encode 'f(address)' ${SEPOLIA_POOL_ADDRESS})],$(cast abi-encode 'f(address)' ${SEPOLIA_REBASE_TOKEN_ADDRESS}),(false,0,0),(false,0,0))]" \
    --rpc-url "${ZKSYNC_SEPOLIA_RPC_URL}" \
    --private-key "${ABHILOV_PRIVATE_KEY}"

echo "=== TESTING DEPOSIT ==="

echo "Depositing ${AMOUNT} wei into Vault..."
cast send "${VAULT_ADDRESS}" \
    --value "${AMOUNT}" \
    --rpc-url "${SEPOLIA_RPC_URL}" \
    --private-key "${ABHILOV_PRIVATE_KEY}" \
    "deposit()"

# Check balance after deposit
SEPOLIA_BALANCE=$(cast balance "${DEPLOYER_ADDRESS}" --erc20 "${SEPOLIA_REBASE_TOKEN_ADDRESS}" --rpc-url "${SEPOLIA_RPC_URL}")
echo "Sepolia rebase token balance after deposit: $SEPOLIA_BALANCE"

echo "=== TESTING CROSS-CHAIN BRIDGE ==="

# Approve CCIP Router to spend tokens
echo "Approving router to spend tokens..."
cast send "${SEPOLIA_REBASE_TOKEN_ADDRESS}" \
    "approve(address,uint256)" "${SEPOLIA_ROUTER}" "${AMOUNT}" \
    --rpc-url "${SEPOLIA_RPC_URL}" \
    --private-key "${ABHILOV_PRIVATE_KEY}"

# Get LINK balance for fees
LINK_BALANCE=$(cast balance "${DEPLOYER_ADDRESS}" --erc20 "${SEPOLIA_LINK_ADDRESS}" --rpc-url "${SEPOLIA_RPC_URL}")
echo "LINK balance: $LINK_BALANCE"

if [ "$LINK_BALANCE" = "0" ]; then
    echo "Warning: No LINK tokens for fees. Bridge transaction may fail."
fi

echo "Bridging tokens from Sepolia to ZKSync..."
BRIDGE_AMOUNT=$((AMOUNT / 2))  # Bridge half the tokens

# Create CCIP message
MESSAGE_DATA=$(cast abi-encode \
    "ccipSend(uint64,(bytes,bytes,(address,uint256)[],address,bytes))" \
    "${ZKSYNC_SEPOLIA_CHAIN_SELECTOR}" \
    "($(cast abi-encode 'f(address)' ${DEPLOYER_ADDRESS}),0x,[(${SEPOLIA_REBASE_TOKEN_ADDRESS},${BRIDGE_AMOUNT})],${SEPOLIA_LINK_ADDRESS},0x)")

cast send "${SEPOLIA_ROUTER}" \
    "${MESSAGE_DATA}" \
    --rpc-url "${SEPOLIA_RPC_URL}" \
    --private-key "${ABHILOV_PRIVATE_KEY}" \
    --gas-limit 500000

echo "Bridge transaction sent. Waiting for cross-chain execution..."

# Check balances after bridge
sleep 10
SEPOLIA_BALANCE_AFTER=$(cast balance "${DEPLOYER_ADDRESS}" --erc20 "${SEPOLIA_REBASE_TOKEN_ADDRESS}" --rpc-url "${SEPOLIA_RPC_URL}")
echo "Sepolia balance after bridge: $SEPOLIA_BALANCE_AFTER"

# Wait a bit more for ZKSync balance to update
echo "Waiting for ZKSync balance to update..."
sleep 30

ZKSYNC_BALANCE=$(cast balance "${DEPLOYER_ADDRESS}" --erc20 "${ZKSYNC_REBASE_TOKEN_ADDRESS}" --rpc-url "${ZKSYNC_SEPOLIA_RPC_URL}")
echo "ZKSync balance after bridge: $ZKSYNC_BALANCE"

echo "=== DEPLOYMENT SUMMARY ==="
echo "Sepolia RebaseToken: $SEPOLIA_REBASE_TOKEN_ADDRESS"
echo "Sepolia Pool: $SEPOLIA_POOL_ADDRESS"
echo "ZKSync RebaseToken: $ZKSYNC_REBASE_TOKEN_ADDRESS"
echo "ZKSync Pool: $ZKSYNC_POOL_ADDRESS"
echo "Vault: $VAULT_ADDRESS"
echo "Deployer: $DEPLOYER_ADDRESS"