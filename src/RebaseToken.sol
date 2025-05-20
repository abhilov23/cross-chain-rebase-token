//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from  "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";


/**
 * @title Rebase Token
 * @author Abhilov Gupta
 * @notice This is a cross-chain rebase token that incentivises users to deposit into a vault.
 * @notice The interest rate in the smart-contract can only decrease.
 * @notice each user will have their own interest rate that is the global interest rate at the time of depositing.
 */



contract RebaseToken is ERC20, Ownable, AccessControl{
   
    error RebaseToken__InterestRateCanOnlyDecrease(uint256 oldInterestRate, uint256 newInterestRate);


    uint256 private constant PRECISION_FACTOR = 1e18;
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");
    uint256 private s_interestRate = 5e10;
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;



    event InterestRateSet(uint256 newInterestRate);

    constructor() ERC20("Rebase Token", "RBT") Ownable(msg.sender){}
     

    function grantMintAndBurnRole(address _user) external onlyOwner{
        _grantRole(MINT_AND_BURN_ROLE, _user);
    }



   /**
   * @notice Set the interest rate in the contract
   * @param _newInterestRate : the new interest rate to set
   * @dev The interest rate can only decrease
   */ 



  function setInterestRate(uint256 _newInterestRate) external onlyOwner {
    // setting up the interest rate
    if(_newInterestRate > s_interestRate){
        revert RebaseToken__InterestRateCanOnlyDecrease(s_interestRate, _newInterestRate);
    }
    s_interestRate = _newInterestRate;
    emit InterestRateSet(_newInterestRate);
  }

  /**
   * @notice returns the current balance of the user
   * @param _user the user address to get the balance of
   * @return the balance of the user
   */

  function principleBalanceOf(address _user) external view returns(uint256){
    return super.balanceOf(_user);
  }





  /**
   * @notice mint the users tokens when they deposit into the vault
   * @param _to the user address to mint the tokens to
   * @param _amount the amount of tokens to mint.
   */

  function mint(address _to, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE){
    _mintAccruedInterest(_to);
    s_userInterestRate[_to] = s_interestRate;
    _mint(_to, _amount);
  }
  
  /**
   * @notice burn the user token when they withdraw from the vault
   * @param _from the user to burn the token from
   * @param _amount the amount of tokens to burn 
   */

  function burn(address _from, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE){
     if(_amount == type(uint256).max){
      _amount = balanceOf(_from);
     }
    _mintAccruedInterest(_from);
    _burn(_from, _amount);
  }




  function getUserInterestRate(address _user) external view returns(uint256){
    return s_userInterestRate[_user];
  } 
   
  /**
   * @notice get the current interest rate in the contract
   * @return the current interest rate in the contract
   */

  function getInterestRate() external view returns(uint256){
    return s_interestRate;
  }



  function balanceOf(address _user) public view override returns(uint256){
   // get the current principle balance (the number of tokens that have actually been minted to the user)
   // multiply the principle balance by interest 
   return super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceLastUpdate(_user) / PRECISION_FACTOR;
  }


  /**
   * @notice Transfer tokens from the sender to another user
   * @param _recipient the user to transfer the tokens to
   * @param _amount the amount of tokens to transfer
   */

  function transfer(address _recipient, uint256 _amount) public override returns (bool){
    // mint the accrued interest to the user
    _mintAccruedInterest(msg.sender);
    _mintAccruedInterest(_recipient);
    if(_amount == type(uint256).max){
      _amount = balanceOf(msg.sender);
    }
    if(balanceOf(_recipient) == 0){
      // set the interest rate for the user
      s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
    }


    // transfer the tokens to the user
    return super.transfer(_recipient, _amount);
  }


  /** 
   * @notice Transfer tokens from the sender to another user
   * @param _sender the user to transfer the tokens from
   * @param _recipient the user to transfer the tokens to
   * @param _amount the amount of tokens to transfer
   */
  
  function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool){
    // mint the accrued interest to the user
    _mintAccruedInterest(_sender);
    _mintAccruedInterest(_recipient);
    if(_amount == type(uint256).max){
      _amount = balanceOf(_sender);
    }
    if(balanceOf(_recipient) == 0){
      // set the interest rate for the user
      s_userInterestRate[_recipient] = s_userInterestRate[_sender];
    }
    return super.transferFrom(_sender, _recipient, _amount);
  }




   function _calculateUserAccumulatedInterestSinceLastUpdate(address _user) internal view returns (uint256 linearInterest){
          //we need to calculate the interest that has accumulated since the last update 
          // this is going to linear growth  with time
          // 1. calculate the time since last update
          // 2. calculate the amount of linear growth
        uint256 timeEclapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];
        linearInterest = PRECISION_FACTOR + (s_userInterestRate[_user] * timeEclapsed) / PRECISION_FACTOR;   
      
      }


  //mint the increased tokens to the users as the time passed by
  function _mintAccruedInterest(address _user) internal {
   // (1) find the current balance of rebase token minted to the user => principle
   uint256 previousPrincipleBalance = super.balanceOf(_user);
   // (2) calculate their current balance including any interest => balanceOf
   uint256 currentBalance = balanceOf(_user);
   // calculate the number of tokens that need to be minted to the user => (2)-(1)
   uint256 balanceIncrease = currentBalance - previousPrincipleBalance;
   // call _mint to mint the tokens to the user
   // set the user's last updated timestamp
   s_userLastUpdatedTimestamp[_user] = block.timestamp;
   if(balanceIncrease > 0){
        _mint(_user, balanceIncrease);

   }
  }

}
