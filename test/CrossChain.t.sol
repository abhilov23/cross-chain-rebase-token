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

import {Client} from "@ccip/contracts/src/v0.8/ccip/libraries/Client.sol";

import {IRouterClient} from "@ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";

contract CrossChainTest is Test{
    address public owner = makeAddr("owner");
    address public user = makeAddr("user");
    uint256 SEND_VALUE = 1e5;
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
        // Create CCIP simulator first before forks
        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        // Create forks
        sepoliaFork = vm.createSelectFork("sepolia-eth");
        arbSepoliaFork = vm.createFork("arb-sepolia");

        // Make important addresses persistent
        vm.makePersistent(owner);
        vm.makePersistent(user);

        // Setup Sepolia network
        vm.selectFork(sepoliaFork);
        vm.allowCheatcodes(address(ccipLocalSimulatorFork));
        setupSepoliaNetwork();
        
        // Setup Arbitrum Sepolia network
        vm.selectFork(arbSepoliaFork);  
        vm.allowCheatcodes(address(ccipLocalSimulatorFork));
        setupArbitrumSepoliaNetwork();
        
        // Configure pools for cross-chain communication
        configureTokenPool(sepoliaFork, address(sepoliaPool), arbSepoliaNetworkDetails.chainSelector, address(arbSepoliaPool), address(arbSepoliaToken));
        configureTokenPool(arbSepoliaFork, address(arbSepoliaPool), sepoliaNetworkDetails.chainSelector, address(sepoliaPool), address(sepoliaToken));
    }

    function setupSepoliaNetwork() internal {
        sepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        
        // Make all CCIP infrastructure persistent
        vm.makePersistent(sepoliaNetworkDetails.routerAddress);
        vm.makePersistent(sepoliaNetworkDetails.linkAddress);
        vm.makePersistent(sepoliaNetworkDetails.rmnProxyAddress);
        vm.makePersistent(sepoliaNetworkDetails.tokenAdminRegistryAddress);
        vm.makePersistent(sepoliaNetworkDetails.registryModuleOwnerCustomAddress);
        vm.makePersistent(sepoliaNetworkDetails.ccipBnMAddress);
        vm.makePersistent(sepoliaNetworkDetails.ccipLnMAddress);
        
        vm.startPrank(owner);
        
        // Deploy our contracts
        sepoliaToken = new RebaseToken();
        vault = new Vault(IRebaseToken(address(sepoliaToken)));
        sepoliaPool = new RebaseTokenPool(
            IERC20(address(sepoliaToken)), 
            new address[](0), 
            sepoliaNetworkDetails.rmnProxyAddress, 
            sepoliaNetworkDetails.routerAddress
        );
        
        // Make our contracts persistent
        vm.makePersistent(address(sepoliaToken));
        vm.makePersistent(address(vault));
        vm.makePersistent(address(sepoliaPool));
        
        // Configure token permissions
        sepoliaToken.grantMintAndBurnRole(address(vault));
        sepoliaToken.grantMintAndBurnRole(address(sepoliaPool));
        
        // Register with CCIP
        RegistryModuleOwnerCustom(sepoliaNetworkDetails.registryModuleOwnerCustomAddress)
            .registerAdminViaOwner(address(sepoliaToken));
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress)
            .acceptAdminRole(address(sepoliaToken));
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress)
            .setPool(address(sepoliaToken), address(sepoliaPool));
            
        vm.stopPrank();
    }

    function setupArbitrumSepoliaNetwork() internal {
        arbSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        
        // Make all CCIP infrastructure persistent
        vm.makePersistent(arbSepoliaNetworkDetails.routerAddress);
        vm.makePersistent(arbSepoliaNetworkDetails.linkAddress);
        vm.makePersistent(arbSepoliaNetworkDetails.rmnProxyAddress);
        vm.makePersistent(arbSepoliaNetworkDetails.tokenAdminRegistryAddress);
        vm.makePersistent(arbSepoliaNetworkDetails.registryModuleOwnerCustomAddress);
        vm.makePersistent(arbSepoliaNetworkDetails.ccipBnMAddress);
        vm.makePersistent(arbSepoliaNetworkDetails.ccipLnMAddress);
        
        vm.startPrank(owner);
        
        // Deploy our contracts
        arbSepoliaToken = new RebaseToken();
        arbSepoliaPool = new RebaseTokenPool(
            IERC20(address(arbSepoliaToken)), 
            new address[](0), 
            arbSepoliaNetworkDetails.rmnProxyAddress, 
            arbSepoliaNetworkDetails.routerAddress
        );
        
        // Make our contracts persistent
        vm.makePersistent(address(arbSepoliaToken));
        vm.makePersistent(address(arbSepoliaPool));
        
        // Configure token permissions
        arbSepoliaToken.grantMintAndBurnRole(address(arbSepoliaPool));
        
        // Register with CCIP
        RegistryModuleOwnerCustom(arbSepoliaNetworkDetails.registryModuleOwnerCustomAddress)
            .registerAdminViaOwner(address(arbSepoliaToken));
        TokenAdminRegistry(arbSepoliaNetworkDetails.tokenAdminRegistryAddress)
            .acceptAdminRole(address(arbSepoliaToken));
        TokenAdminRegistry(arbSepoliaNetworkDetails.tokenAdminRegistryAddress)
            .setPool(address(arbSepoliaToken), address(arbSepoliaPool));
            
        vm.stopPrank();
    }

    function configureTokenPool(uint256 fork, address localPool, uint64 remoteChainSelector, address remotePool, address remoteTokenAddress) public {
        vm.selectFork(fork);
        vm.startPrank(owner);
        
        TokenPool.ChainUpdate[] memory chainsToAdd = new TokenPool.ChainUpdate[](1);
         
        chainsToAdd[0] = TokenPool.ChainUpdate({
           remoteChainSelector: remoteChainSelector,
           allowed: true,
           remotePoolAddress: abi.encode(remotePool),
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
        TokenPool(localPool).applyChainUpdates(chainsToAdd);
        vm.stopPrank();
    }

   function bridgeTokens(uint256 amountToBridge, uint256 localFork, uint256 remoteFork, Register.NetworkDetails memory localNetworkDetails, Register.NetworkDetails memory remoteNetworkDetails, RebaseToken localToken, RebaseToken remoteToken) public {
      
        vm.selectFork(localFork);

        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: address(localToken),
            amount: amountToBridge
        });

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(user),
            data:"",
            tokenAmounts: tokenAmounts,
            feeToken: localNetworkDetails.linkAddress,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV2({
                gasLimit: 500_000,
                allowOutOfOrderExecution: false
            }))
        });
          
        uint256 fee = IRouterClient(localNetworkDetails.routerAddress).getFee(remoteNetworkDetails.chainSelector, message);
        ccipLocalSimulatorFork.requestLinkFromFaucet(user, fee);
        vm.prank(user);
        IERC20(localNetworkDetails.linkAddress).approve(localNetworkDetails.routerAddress, fee);
        vm.prank(user);
        IERC20(address(localToken)).approve(localNetworkDetails.routerAddress, amountToBridge);
        uint256 localBalanceBefore = localToken.balanceOf(user);
        vm.prank(user);  
        IRouterClient(localNetworkDetails.routerAddress).ccipSend(remoteNetworkDetails.chainSelector, message);
        uint256 localBalanceAfter = localToken.balanceOf(user);
        assertEq(localBalanceAfter,localBalanceBefore - amountToBridge);

        vm.selectFork(remoteFork);
        vm.warp(block.timestamp + 20 minutes);
        uint256 remoteBalanceBefore = remoteToken.balanceOf(user);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(remoteFork);
        uint256 remoteBalanceAfter = remoteToken.balanceOf(user);
        assertEq(remoteBalanceAfter, remoteBalanceBefore + amountToBridge);
   }

}