pragma solidity ^0.8.0;

import "./Campaign.sol";
import "./ICampaignFactory.sol";

// Using @openzeppelin contracts for better auditing.
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Context.sol";


// When deploying & initilising
// 1. Deploy the Campaign contract
// 2. Deploy the CampaignFactory contract
// 3. Set the masterCampaignAddress in the Factory Contract as the Campaign contract address
// 4. Set the currencies wanted in the mapping as (index, address)


contract CampaignFactory is Context{
    using SafeMath for uint;

    struct CampaignSaved {
        address campaignAddress;
        uint id;
    }

    mapping(address => bool) public blacklist;
    mapping(address => uint) public creatorCampaignNumber;
    mapping(address => CampaignSaved) public campaigns;
    mapping(uint => address) public currencies;

    address[]  public allCrowdFund;
    address public masterCampaignAddress;
    address public token;
    address owner;

    uint256 public nbCampaign;
    uint public indexCurrencies;
    
    // TOKEN ADDRESSES

    event CampaignCreated(address campaign, address creator, uint256 campaignId, uint goal);

    modifier isWhitelisted() {
        require(blacklist[msg.sender] == false, "You are not allowed to interract with the contract");
        _;
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "You are not the Owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        address usdc = address(0x2f3A40A3db8a7e3D09B0adfEfbCe4f6F81927557);
        setCurrencies(0, usdc);
        setCurrencies(1, 0x0000000000000000000000000000000000000000);
        address bbst = address(0x24600539D8Fa2D29C58366512d08EE082A6c0cB3);
        setCurrencies(2, bbst);
        nbCampaign = 0;
        indexCurrencies = 0;
    }

    // Setting up the proxy
    function setMasterCampaignAddress(address newAddress) onlyOwner() public returns(address) {
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

    function setCurrencies(uint index, address currencyAddress) onlyOwner() public returns(bool) {
        require(index >= 0, "index must be positive");
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
        uint tokenChoice,
        uint256[] memory amounts_,
        int256[] memory stock_
        ) payable external isWhitelisted() returns(bool) {
            require(msg.sender != address(0), "address not valid");
            require(tokenChoice >= 0, "cannot be less than 0");
            // Setting up the proxy
            address newCampaign = Clones.clone(masterCampaignAddress);
            
            address payable nA = payable(newCampaign);
            Reward(0x6714adc5a76F50c9deC4FbE672C7bdFb41828F88).addToAllowed(nA);
            Campaign(nA).initialize(payable(msg.sender), nbCampaign, goal_, startTimestamp_, endTimestamp_, currencies[tokenChoice], amounts_, stock_);
            
            uint crCampaignNumber = creatorCampaignNumber[msg.sender];
            campaigns[msg.sender] = CampaignSaved(newCampaign, crCampaignNumber);
            nbCampaign += 1;
            emit CampaignCreated(nA, msg.sender, nbCampaign, goal_);
            return true;
    }


    // **************************** //
    // *         Functions        * //
    // **************************** //

    // to change the owner of the contract
    function changeOwner(address newOwner) public onlyOwner() {
        owner = newOwner;
    }


    function addToBlacklist(address newAddress) onlyOwner() public {
        blacklist[newAddress] = true;
    }
    
    function removeFromBlacklist(address addressToRemove) onlyOwner() public {
        blacklist[addressToRemove] = false;
    }

    function getCampaign(address creator) external view returns(CampaignSaved memory _campaign) {
        return campaigns[creator];
    }

}