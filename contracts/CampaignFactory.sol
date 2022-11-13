pragma solidity ^0.8.0;

import "./Campaign.sol";

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


contract CampaignFactory is Context {
    using SafeMath for uint;

    // event emmitted at campaign creation
    event CampaignCreated(address campaign, address creator, uint256 campaignId, address currency);

    mapping(address => bool) public blacklist;  // blacklisted addresses
    mapping(uint => address) public currencies; // mapping index => address of a currency's ERC20 contract (for ETH => maps to address(0))

    address public masterCampaignAddress;      // Address of the "Campaign" Master contract deployed. We will clone that to create campaigns from this factory.
    address owner;  // The owner of the contract
    address public BBSTAddr = address(0x000000000000000000000000000000000000dEaD); // Address of the BBST Token

    uint256 public nbCampaign; // number of campaigns created with this factory

    bool feesActive = false;

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

        // set the available currencies with corresponding address. 0 = BUSD / 1 = BNB / 2 = BBST
        address busd = address(0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee);
        setCurrencies(0, busd);
        setCurrencies(1, address(0)); // set ETH/BNB with the 0 address
        // POUR LA V1 PAS UTILE VARIABLE BBST DISPO
        // address bbst = address(0x24600539D8Fa2D29C58366512d08EE082A6c0cB3);
        // setCurrencies(2, bbst);

        // initialize counters to 0
        nbCampaign = 0;
    }

    // Setting up the proxy
    function setMasterCampaignAddress(address newAddress) onlyOwner() public returns(address) {
        masterCampaignAddress = newAddress;
        return(masterCampaignAddress);
    }

    // Setting BBST Token Address
    function setBBSTAddr(address addr) external onlyOwner() {
        BBSTAddr = address(addr);
    }

    // setting the status of the fees (active or not)
    function setFeesActive(bool active) external onlyOwner() {
        feesActive = active;
    }

    // **************************** //
    // *       Currencies         * //
    // **************************** //

    function setCurrencies(uint index, address currencyAddress) onlyOwner() public returns(bool) {
        require(index >= 0, "index must be positive");
        currencies[index] = currencyAddress;
        return(true);
    }

    // **************************** //
    // *      Initialisation      * //
    // **************************** //

    /* Function used to create a new campaign.
    After basic checks on the inputs, create a new instance of Campaign (cloning the master) and initialize it with the parameters */
    function createCampaign(
        uint goal_,
        uint startTimestamp_, 
        uint endTimestamp_,
        uint tokenChoice,   // 0, 1 or 2 : will determine the currency used thanks to the "currencies" mapping
        uint256[] memory amounts_,
        int256[] memory stock_
        ) payable external isWhitelisted() returns(bool) {

            // check if the chosen token index is for BNB (<=> 1), otherwise, check if the index has a corresponding address in the currencies mapping
            require(tokenChoice == 1 || currencies[tokenChoice] != address(0), "Wrong currency index");
            
            // Create a new Campaign instance
            address newCampaign = Clones.clone(masterCampaignAddress);
            address payable nA = payable(newCampaign);

            //Add the address of the newly created campaign to the allowed address on the Reward contract
            Reward(0xe9Dd017ac8B1F5c3603AA182d038cfD660F6056f).addToAllowed(nA);
            //Initialize the newly created campaign
            Campaign(nA).initialize(payable(msg.sender), nbCampaign, goal_, startTimestamp_, endTimestamp_, currencies[tokenChoice], address(BBSTAddr), feesActive, amounts_, stock_);
            
            nbCampaign += 1;

            emit CampaignCreated(nA, msg.sender, nbCampaign, currencies[tokenChoice]);
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
}