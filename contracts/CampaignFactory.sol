pragma solidity ^0.8.0;

import './Campaign.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';


contract CampaignFactory {

    using SafeMath for uint;

    mapping(address => Campaign) public campaigns;
    address[]  public allCrowdFund;

    uint256 public nbCampaign;
    Campaign private newCampaign;
    
    event CampaignCreated(address creator, uint nbCampaign, uint goal);

    constructor() {
        nbCampaign = 0;
    }

    function createCampaign(
        uint goal_, 
        uint startTimestamp_, 
        uint endTimestamp_, 
        bool partialGoal_, 
        uint nbTiers_,
        uint[] memory listTiers_
        ) 
        payable
        public
    returns(bool) {
        require(msg.sender != address(0), 'address not valid');
        newCampaign = new Campaign(payable(msg.sender), nbCampaign, goal_, startTimestamp_, endTimestamp_, partialGoal_, nbTiers_, listTiers_);
        campaigns[msg.sender] = newCampaign;
        nbCampaign += 1;
        emit CampaignCreated(msg.sender, nbCampaign, goal_);
        return true;
    }


}