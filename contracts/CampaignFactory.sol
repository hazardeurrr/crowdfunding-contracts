pragma solidity ^0.8.0;

import "./Campaign.sol";
import "./ICampaignFactory.sol";

// Using @openzeppelin contracts for better auditing.
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";


// When deploying & initilising
// 1. Deploy the Campaign contract
// 2. Deploy the CampaignFactory contract
// 3. Set the masterCampaignAddress in the Factory Contract as the Campaign contract address
// 4. Set the currencies wanted in the mapping as (index, address)


contract CampaignFactory is Ownable, ICampaignFactory {
    using SafeMath for uint;

    mapping(address => bool) public blacklist;
    struct CampaignSaved {
        address campaignAddress;
        uint id;
    }

    mapping(uint => address) public currencies;
    uint public indexCurrencies;
    mapping(address => CampaignSaved) public campaigns;
    mapping(address => uint) public creatorCampaignNumber;
    address[]  public allCrowdFund;
    address public masterCampaignAddress;
    uint256 public nbCampaign;
    address public token;
    
    // TOKEN ADDRESSES


    modifier isWhitelisted() {
        require(blacklist[msg.sender] == false, 'You are not allowed to interract with the contract');
        _;
    }

    constructor(address masterCampaignAddress_) {
        address usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        address bbst = address(0);
        nbCampaign = 0;
        indexCurrencies = 0;
        masterCampaignAddress = masterCampaignAddress_;
    }

    function setMasterCampaignAddress(address newAddress) public onlyOwner returns(address) {
        masterCampaignAddress = newAddress;
        return(masterCampaignAddress);
    }

    function getCurrencies(uint index) public returns(address) {
        require(index >= 0, "index must be positive");
        indexCurrencies += 1;
        return(currencies[index]);
    }

    function setCurrencies(uint index, address currencyAddress) public returns(bool) {
        currencies[index] = currencyAddress;
        return(true);
    }

    function createCampaign(
        uint goal_, 
        uint startTimestamp_, 
        uint endTimestamp_, 
        bool partialGoal_,
        uint tokenChoice,
        uint nbTiers_,
        uint[] memory listTiers_
        ) payable external override isWhitelisted() returns(bool) {
            require(msg.sender != address(0), "address not valid");
            address newCampaign = Clones.clone( masterCampaignAddress);
            address payable nA = payable(newCampaign);
            ICampaign(nA).initialize(payable(msg.sender), nbCampaign, goal_, startTimestamp_, endTimestamp_, partialGoal_, token, nbTiers_, listTiers_);
            uint crCampaignNumber = creatorCampaignNumber[msg.sender];
            campaigns[msg.sender] = CampaignSaved(newCampaign, crCampaignNumber);
            nbCampaign += 1;
            emit CampaignCreated(msg.sender, nbCampaign, goal_);
            return true;
    }

    function addToBlacklist(address newAddress) public override {
        blacklist[newAddress] = true;
    }
    
    function removeFromBlacklist(address addressToRemove)  public override  {
        blacklist[addressToRemove] = false;
    }

    function getCampaign(address creator) external view returns(CampaignSaved memory _campaign) {
        return campaigns[creator];
    }

}