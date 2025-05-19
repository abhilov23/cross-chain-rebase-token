//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from  "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Rebase Token
 * @author Abhilov Gupta
 * @notice This is a cross-chain rebase token that incentivises users to deposit into a vault.
 * @notice The interest rate in the smart-contract can only decrease.
 * @notice each user will have their own interest rate that is the global interest rate at the time of depositing.
 */



contract RebaseToken is ERC20{
   
    error RebaseToken__InterestRateCanOnlyDecrease(uint256 oldInterestRate, uint256 newInterestRate);


    uint256 private constant PRECISION_FACTOR = 1e18;
    uint256 private s_interestRate = 5e10;
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;



    event InterestRateSet(uint256 newInterestRate);

    constructor() ERC20("Rebase Token", "RBT"){}
    
   /*
   * @notice Set the interest rate in the contract
   * param _newInterestRate : the new interest rate to set
   * @dev The interest rate can only decrease
   */ 



  function setInterestRate(uint256 _newInterestRate) external {
    // setting up the interest rate
    if(_newInterestRate < s_interestRate){
        revert RebaseToken__InterestRateCanOnlyDecrease(s_interestRate, _newInterestRate);
    }
    s_interestRate = _newInterestRate;
    emit InterestRateSet(_newInterestRate);
  }

  function mint(address _to, uint256 _amount) external{
    _mintAccruedInterest(_to);
    s_userInterestRate[_to] = s_interestRate;
    _mint(_to, _amount);
  }

  function getUserInterestRate(address _user) external view returns(uint256){
    return s_userInterestRate[_user];
  } 

  function balanceOf(address _user) public view override returns(uint256){
   // get the current principle balance (the number of tokens that have actually been minted to the user)
   // multiply the principle balance by interest 
   return super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceLastUpdate(_user) / PRECISION_FACTOR;
  }




   function _calculateUserAccumulatedInterestSinceLastUpdate(address _user) internal view returns (uint256 linearInterest){
          //we need to calculate the interest that has accumulated since the last update 
          // this is going to linear growth  with time
          // 1. calculate the time since last update
          // 2. calculate the amount of linear growth
        uint256 timeEclapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];
        linearInterest = (PRECISION_FACTOR + (s_userInterestRate[_user] * timeEclapsed));
        }



  function _mintAccruedInterest(address _user) internal {
   // (1) find the current balance of rebase token minted to the user => principle
   // (2) calculate their current balance including any interest => balanceOf
   // calculate the number of tokens that need to be minted to the user => (2)-(1)
   // call _mint to mint the tokens to the user
   // set the user's last updated timestamp
   s_userLastUpdatedTimestamp[_user] = block.timestamp;
  }

}
