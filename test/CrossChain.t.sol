//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";

import {RebaseToken} from "../src/RebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {Vault} from "../src/Vault.sol";

import {IERC20} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {IRebaseToken} from "../src/interfaces/IRebaseToken.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {RegistryModuleOwnerCustom} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {TokenPool} from "@ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {RateLimiter} from "@ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";



contract CrossChainTest is Test{
    address public owner = makeAddr("owner");
    uint256 sepoliaFork;
    uint256 arbSepoliaFork;

    CCIPLocalSimulatorFork ccipLocalSimulatorFork;


    RebaseToken sepoliaToken;
    RebaseToken arbSepoliaToken;

    Vault vault;

    RebaseTokenPool sepoliaPool;
    RebaseTokenPool arbSepoliaPool;


    Register.NetworkDetails sepoliaNetworkDetails;
    Register.NetworkDetails arbSepoliaNetworkDetails;
     

    function setUp() public {
       
        sepoliaFork = vm.createSelectFork("sepolia-eth");
        arbSepoliaFork = vm.createFork("arb-sepolia");

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));


        // Deploying and configure on sepolia

        sepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        vm.startPrank(owner);
        sepoliaToken = new RebaseToken();
        vault = new Vault(IRebaseToken(address(sepoliaToken)));
        sepoliaPool = new RebaseTokenPool(IERC20(address(sepoliaToken)), new address[](0), sepoliaNetworkDetails.rmnProxyAddress, sepoliaNetworkDetails.routerAddress);
        sepoliaToken.grantMintAndBurnRole(address(vault));
        sepoliaToken.grantMintAndBurnRole(address(sepoliaPool));
        RegistryModuleOwnerCustom(sepoliaNetworkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(address(sepoliaToken));
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(sepoliaToken));
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress).setPool(address(sepoliaToken),address(sepoliaPool));
        vm.stopPrank();

        // Deploying and configure on arbitrum sepolia
        vm.selectFork(arbSepoliaFork);
        arbSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        vm.startPrank(owner);
        arbSepoliaToken = new RebaseToken();
        arbSepoliaPool = new RebaseTokenPool(IERC20(address(arbSepoliaToken)), new address[](0), arbSepoliaNetworkDetails.rmnProxyAddress, arbSepoliaNetworkDetails.routerAddress);
        arbSepoliaToken.grantMintAndBurnRole(address(arbSepoliaPool));
        RegistryModuleOwnerCustom(arbSepoliaNetworkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(address(arbSepoliaToken));
        TokenAdminRegistry(arbSepoliaNetworkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(arbSepoliaToken));
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress).setPool(address(sepoliaToken),address(sepoliaPool));
        configureTokenPool(sepoliaFork, address(sepoliaPool), arbSepoliaNetworkDetails.chainSelector, address(arbSepoliaPool), address(arbSepoliaToken));
        configureTokenPool(arbSepoliaFork, address(arbSepoliaPool), sepoliaNetworkDetails.chainSelector, address(sepoliaPool), address(sepoliaToken));
        vm.stopPrank();
    }

    function configureTokenPool(uint256 fork, address localPool, uint64 remoteChainSelector, address remotePool, address remoteTokenAddress) public {
        vm.selectFork(fork);
        vm.startPrank(owner);
        bytes[] memory remotePoolAddresses = new bytes[](1);
        remotePoolAddresses[0] = abi.encode(remotePool);
        TokenPool.chainUpdate[] memory chainsToAdd = new TokenPool.chainUpdate[](1);
         

        // struct ChainUpdate {
        // uint64 remoteChainSelector; // ──╮ Remote chain selector
        // bool allowed; // ────────────────╯ Whether the chain should be enabled
        // bytes remotePoolAddress; //        Address of the remote pool, ABI encoded in the case of a remote EVM chain.
        // bytes remoteTokenAddress; //       Address of the remote token, ABI encoded in the case of a remote EVM chain.
        // RateLimiter.Config outboundRateLimiterConfig; // Outbound rate limited config, meaning the rate limits for all of the onRamps for the given chain
        // RateLimiter.Config inboundRateLimiterConfig; // Inbound rate limited config, meaning the rate limits for all of the offRamps for the given chain
        // }
        chainsToAdd[0] = TokenPool.chainUpdate({
           remoteChainSelector: remoteChainSelector,
           remotePoolAddresses: remotePoolAddresses,
           remoteTokenAddress: abi.encode(remoteTokenAddress),
           outboundRateLimiterConfig: RateLimiter.Config({
                isEnabled: false,
                capacity: 0,
                rate: 0
            }),
            inboundRateLimiterConfig: RateLimiter.Config({
                 isEnabled: false,
                 capacity: 0,
                 rate: 0
                })
        });
        TokenPool(localPool).applyChainUpdates(new uint64[](0), chainsToAdd);
    }
}