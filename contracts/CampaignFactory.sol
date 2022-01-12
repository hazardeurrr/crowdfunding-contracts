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


contract CampaignFactory {
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

    event CampaignCreated(address campaign, address creator, uint256 campaignId, uint goal);

    modifier isWhitelisted() {
        require(blacklist[msg.sender] == false, 'You are not allowed to interract with the contract');
        _;
    }

    constructor(address masterCampaignAddress_) {
        address usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        setCurrencies(0, usdt);
        nbCampaign = 0;
        indexCurrencies = 0;
        masterCampaignAddress = masterCampaignAddress_;
    }

    // Setting up the proxy
    function setMasterCampaignAddress(address newAddress) public returns(address) {
        masterCampaignAddress = newAddress;
        return(masterCampaignAddress);
    }

    // **************************** //
    // *       Currencies         * //
    // **************************** //

    function getCurrencies(uint index) public view returns(address) {
        require(index >= 0, "index must be positive");
        return(currencies[index]);
    }

    function setCurrencies(uint index, address currencyAddress) public returns(bool) {
        currencies[index] = currencyAddress;
        return(true);
    }

    // **************************** //
    // *      Initialisation      * //
    // **************************** //

    function createCampaign(
        uint goal_, 
        uint startTimestamp_, 
        uint endTimestamp_, 
        bool partialGoal_,
        uint tokenChoice,
        uint nbTiers_,
        uint[] memory listTiers_
        ) payable external isWhitelisted() returns(bool) {
            require(msg.sender != address(0), "address not valid");
            require(tokenChoice >= 0, "cannot be less than 0");
            // Setting up the proxy
            address newCampaign = Clones.clone(masterCampaignAddress);
            
            address payable nA = payable(newCampaign);
            Campaign(nA).initialize(payable(msg.sender), nbCampaign, goal_, startTimestamp_, endTimestamp_, partialGoal_, currencies[tokenChoice], nbTiers_, listTiers_);
            
            uint crCampaignNumber = creatorCampaignNumber[msg.sender];
            campaigns[msg.sender] = CampaignSaved(newCampaign, crCampaignNumber);
            nbCampaign += 1;
            emit CampaignCreated(nA, msg.sender, nbCampaign, goal_);
            return true;
    }


    // **************************** //
    // *         Functions        * //
    // **************************** //


    function addToBlacklist(address newAddress) public {
        blacklist[newAddress] = true;
    }
    
    function removeFromBlacklist(address addressToRemove)  public {
        blacklist[addressToRemove] = false;
    }

    function getCampaign(address creator) external view returns(CampaignSaved memory _campaign) {
        return campaigns[creator];
    }

}