pragma solidity ^0.8.0;

import './Campaign.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract CampaignFactory is Ownable {

    using SafeMath for uint;

    mapping(address => bool) public blacklist;

    mapping(address => Campaign) public campaigns;
    address[]  public allCrowdFund;

    uint256 public nbCampaign;
    Campaign private newCampaign;
    
    event CampaignCreated(address creator, uint nbCampaign, uint goal);

    modifier isWhitelisted() {
        require(blacklist[msg.sender] == false, 'You are not allowed to interract with the contract');
        _;
    }

    constructor() {
        nbCampaign = 0;
    }

    function createCampaign(
        uint goal_, 
        uint startTimestamp_, 
        uint endTimestamp_, 
        bool partialGoal_,
        bool tokenChoice,
        uint nbTiers_,
        uint[] memory listTiers_
        ) 
        payable
        public
        isWhitelisted()
    returns(bool) {
        require(msg.sender != address(0), 'address not valid');
        if (tokenChoice == 0) {
            // Instantiate the BBST contract 
        } else if (tokenChoice == 1) {
            // Instanciate the USDT contract
        } else if (tokenChoice == 2){
            // Instanciate ETH
        }else {
            // By default ETH
        }
        newCampaign = new Campaign(payable(msg.sender), nbCampaign, goal_, startTimestamp_, endTimestamp_, partialGoal_, token, nbTiers_, listTiers_);
        campaigns[msg.sender] = newCampaign;
        nbCampaign += 1;
        emit CampaignCreated(msg.sender, nbCampaign, goal_);
        return true;
    }



    function addToBlacklist(address newAddress) public {
        blacklist[newAddress] = true;
    }
    
    function removeFromBlacklist(address addressToRemove) public {
        blacklist[addressToRemove] = false;
    }


}