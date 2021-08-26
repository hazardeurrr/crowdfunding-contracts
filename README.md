# crowdfunding-contracts

## Contracts

- Blockboosted : Our ERC20 native token. It mints the token to the sender's address
- Campaign : Contract to manage the campaign
    -  1 project -> 1 campaign contract deployed
    - Instantiate the parameters in the constructor to setup the campaign and then managed the state of the campaign to receive funds and eventually send them to the creator if the campaign succeed
- CampaignFactory : Factory that enables to create the campaigns and send the parameters
- Cashback : calculate the cashback for each participation to a campaign
    - Made to incite users to participate
- Claimtoken : Allowing users to withdraw the amount of token that the Cashback contract calculated
- ICO : Handles the ICO, once the BBST tokens are created, this contract receives the amount for the ICO and allows users to buy the token
 