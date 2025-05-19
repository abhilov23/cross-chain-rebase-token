# Cross-chain Rebase token

1. A protocol that allows users to deposit into a vault and in return, receiver rebase tokens that represent their underlying balance.
2. Rebase token => balanceOf function is dynamic to show the changing balance with time. 
   - Balance increases linearly with time.
   - Mint tokens to our users every time they perform an action (minting, burning, transferring or... bridging)
3. Interest rate
   - individually set an interest rate or each user base on some global interest rate of the protocol at the time the user deposit into the vault.
   - This global interest rate can only decrease to incetivise/reward early adaptors.
   - Increase token adoption
