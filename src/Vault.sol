//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRebaseToken} from "./interfaces/IRebaseToken.sol";


contract Vault {
  // we need to pass the token address to the constructor
  // create a deposit function that mints tokens to the user
  // create a redeem function that burns tokens from the user and send the user ETH
  // Create a way to add rewards to the vault

   IRebaseToken private immutable i_rebaseToken;


   event Deposit(address indexed user, uint256 amount);
   event Redeem(address indexed user, uint256 amount);

    error Vault__RedeemFailed();


  constructor(IRebaseToken _rebaseToken) {
    i_rebaseToken = _rebaseToken;
  }

  receive() external payable {}

  /**
  * @notice Deposit ETH into the vault and mint rebase-tokens in return
   */


  function deposit() external payable {
    // we need to use the amount of eth the user has sent to mint tokens to the user
    i_rebaseToken.mint(msg.sender, msg.value);
    emit Deposit(msg.sender, msg.value);
  }


  
  /**
   * @notice Allow user to redeem their rebase-tokens for ETH
   * @dev The amount of rebase-tokens minted is equal to the amount of ETH deposited
   * @param _amount : the amount of ETH to redeem
   */

    function redeem(uint256 _amount) external {
        // we need to burn the tokens from the user and send them ETH
        i_rebaseToken.burn(msg.sender, _amount);
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        if(!success) {
            revert Vault__RedeemFailed();
        }
        emit Redeem(msg.sender, _amount);
    }

   /**
    * @notice Get the address of the rebase token
    * 
    */

  function getRebaseTokenAddress() external view returns (address) {
    return address(i_rebaseToken);
  }



}