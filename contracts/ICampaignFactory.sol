pragma solidity ^0.8.0;

import './Campaign.sol';
// import './Proxy.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// Deploying 
// Deploy first the Campaign contract first and in the callback deploy the CampaignFactory and set the Campaign address in the constructor of the 
// CampaignFactory



interface ICampaignFactory {
   
    event CampaignCreated(address creator, uint nbCampaign, uint goal);


    function createCampaign(
        uint goal_, 
        uint startTimestamp_, 
        uint endTimestamp_, 
        bool partialGoal_,
        uint tokenChoice,
        uint nbTiers_,
        uint[] memory listTiers_
        ) payable external returns(bool);

    function addToBlacklist(address newAddress) external ;
    
    function removeFromBlacklist(address addressToRemove) external;

}