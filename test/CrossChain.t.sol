//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";

import {RebaseToken} from "../src/RebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {Vault} from "../src/Vault.sol";

import {IRebaseToken} from "../src/interfaces/IRebaseToken.sol";
import {CCIPLocalSimulatorFork} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";



contract CrossChainTest is Test{
    address constant owner = makeAddr("owner");
    uint256 sepoliaFork;
    uint256 arbSepoliaFork;

    CCIPLocalSimulatorFork ccipLocalSimulatorFork;


    RebaseToken sepoliaToken;
    RebaseToken arbSepoliaToken;

    Vault vault;

    function setUp() public {
       
        sepoliaFork = vm.createSepoliaFork("sepolia-eth");
        arbSepoliaFork = vm.createArbitrumSepoliaFork("arb-sepolia");

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));


        // Deploying and configure on sepolia
        vm.startPrank(owner);
        sepoliaToken = new RebaseToken();
        vault = new Vault(IRebaseToken(sepoliaToken));
        vm.stopPrank();

        // Deploying and configure on arbitrum sepolia
        vm.selectFork(arbSepoliaFork);
        vm.startPrank(owner);
        arbSepoliaToken = new RebaseToken();
        vm.stopPrank();

    }
}