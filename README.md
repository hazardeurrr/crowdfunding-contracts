# crowdfunding-contracts
Smart-contracts for BlockBoosted (https://blockboosted.com)

Branches :
V2 => currently used contracts
creators => contracts for BlockBoosted for Creators (with the introduction of NFTs for each donation and different process from blockboosted crowdfunding)
nfts => test for an nft marketplace

## Contracts

- Blockboosted : Our ERC20 native token.
- Campaign : Contract to manage a crowdfunding campaign
    -  1 project -> 1 campaign contract deployed
    - Instantiate the parameters in the constructor to setup the campaign
    - Every action on a campaign happens here : payments, withdrawal...
- CampaignFactory : Factory that enables to create the campaigns and send the parameters to the newly created campaign
- PaymentHandler : handle the payments in ERC20 (we delegate the payment to this contract to prevent several allowance checks if someone gives money to different campaigns)
- Rewards : handle the rewards program => initially, each payment should give you the opportunity to get rewarded in BBST. Rewards would be distributed every week according to your volume of transaction compared to the others on the protocol, with a maximum amount amount per address. 

More on how it works in our WhitePaper :
 [BlockBoosted_Whitepaper_V2.pdf](https://github.com/hazardeurrr/crowdfunding-contracts/files/14028914/BlockBoosted_Whitepaper_V2.pdf)
