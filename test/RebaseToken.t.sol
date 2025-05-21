//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/interfaces/IRebaseToken.sol";

contract RebaseTokenTest is Test {
    RebaseToken private rebaseToken;
    Vault private vault;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");


    function setUp() public {
        vm.startPrank(owner);
        rebaseToken = new RebaseToken(); //deploying rebase token
        vault = new Vault(IRebaseToken(address(rebaseToken)));  //deploying the vault token
        rebaseToken.grantMintAndBurnRole(address(vault));
        (bool success,) = payable(address(vault)).call{value: 1e18}("");
        vm.stopPrank();
    }

    function addRewardsToVault(uint256 rewardAmount) public {
        (bool success,) = payable(address(vault)).call{value: rewardAmount}("");
    }



    function testDepositLinear(uint256 amount) public{
       amount = bound(amount, 1e5, type(uint96).max);
       
        // 1. deposit
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value:amount}();
        // 2. check our rebase token balance
        uint256 startBalance = rebaseToken.balanceOf(user);
        console.log("startBalance: ", startBalance);
        assertEq(startBalance, amount);
        // 3. wrap the time and wrap the token again
        vm.warp(block.timestamp + 1 hours);
        
        uint256 middleBalance = rebaseToken.balanceOf(user);
        assertGt(middleBalance, startBalance);
        // 4. wrap the time again but the same amount and check the balance again
        vm.warp(block.timestamp + 1 hours);
        uint256 endBalance = rebaseToken.balanceOf(user);
        assertGt(endBalance, middleBalance);
        
        

        assertApproxEqAbs(endBalance - middleBalance, middleBalance - startBalance,  1);
        
        vm.stopPrank();
    }

    function testRedeemStraightAway(uint256 amount) public {
         amount = bound(amount, 1e5, type(uint96).max);
        // 1. deposit   
        vm.startPrank(user); // says that all the transactions are from the user
        vm.deal(user, amount); // gives the user some ether amount
        vault.deposit{value:amount}(); // deposits the ether into the vault and mints the rebase token on the basis of the ether deposited by the user
        // 2. check our rebase token balance
        assertEq(rebaseToken.balanceOf(user), amount);
        // 3. redeem the tokens
        vault.redeem(type(uint256).max);
        assertEq(rebaseToken.balanceOf(user), 0);
        assertEq(address(user).balance, amount);
        vm.stopPrank();
    }
    

    // checking the redeem function after some time has passed
    // the redeem function should return the amount of ether deposited by the user + interest
    function testRedeemAfterTimePassed(uint256 depositAmount, uint256 time) public {
        time = bound(time, 1000, 10 * 365 days);
        depositAmount = bound(depositAmount, 1e5, type(uint96).max);
        // 1. deposit
        vm.deal(user, depositAmount);
                vm.prank(user);
        vault.deposit{value:depositAmount}();


        //wrap the time
        vm.warp(block.timestamp + time);
        uint256 balanceAfterSomeTime = rebaseToken.balanceOf(user);
        //adding the rewards to the vault
        vm.deal(owner, balanceAfterSomeTime - depositAmount);
        vm.prank(owner);
        addRewardsToVault(balanceAfterSomeTime - depositAmount );
        //redeem 
        vm.prank(user);
        vault.redeem(type(uint256).max);
         
        uint256 ethBalance = address(user).balance;

        assertEq(ethBalance, balanceAfterSomeTime);
        assertGt(ethBalance, depositAmount);
    }



}