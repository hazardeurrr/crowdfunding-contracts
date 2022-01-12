pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./ICampaign.sol";

contract Campaign is ICampaign, Context {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    enum State {
        NotStarted,
        Fundraising,
        Successfull,
        Refund,
        Canceled
    }
    address factory;
    

    // General information about the campaign
    uint public campaign_id;
    address payable public creator;
    uint public goal;
    uint256 public totalBalance;
    State public state;
    address public campaign_address;
    bool public partialGoal;
    address private token;
    uint nbTiers;

    address owner;
    

    // Starting and ending date for the campaign
    uint public startTimestamp;
    uint public endTimestamp;

    // Tiers
    struct Tiers {
        uint index;
        uint price;
        uint quantity;
    }

    Tiers[] public tiersList;

    mapping(address => uint) public contributions;
    mapping(address => uint) public contributionsTiers;


    constructor() {
        owner = msg.sender;
    }

    // **************************** //
    // *         Modifiers        * //
    // **************************** //

    modifier changeState(State state_) {
        require(state != state_, "State must be different");
        state = state_;
        _;
    }

    modifier verifyState(State state_) {
        require(state == state_, "State must be the same");
        _;
    }

    modifier validAddress(address from) {
        require(from != address(0), "Cannot be the address(0)");
        _;
    }

    modifier validAmount(uint amount_) {
        require(amount_ > 0, "Amount cannot be equal or less than 0");
        _;
    }

    modifier ETHOnly() {
        require(token == address(address(0)), "[WARNING] This campaign only receives ETH");
        _;
    }

    modifier ERC20Only() {
        require(token != address(address(0)), "[WARNING] This campaign only receives ERC20");
        _;
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "You are not the Owner");
        _;
    }
    
    modifier onlyFactory() {
        require(factory == _msgSender(), "You are not the Factory");
        _;
    }
    
    modifier onlyCreator() {
        require(creator == _msgSender(), "You are not the Creator of the campaign");
        _;
    }


    // **************************** //
    // *         Functions        * //
    // **************************** //

    function initialize(
        address payable creator_,
        uint campaign_id_,
        uint goal_,
        uint startTimestamp_,
        uint endTimestamp_,
        bool partialGoal_,
        address token_,
        uint nbTiers_,
        uint[] memory tiers_
        ) override external {
            creator = creator_;
            campaign_id = campaign_id_;
            goal = goal_;
            startTimestamp = startTimestamp_;
            endTimestamp = endTimestamp_;
            state = State.Fundraising;
            totalBalance = 0;
            partialGoal = partialGoal_;
            require(nbTiers_ == tiers_.length, "Not compatible");
            nbTiers = nbTiers_;
            addTiersFromList(tiers_);
            token = token_;
            campaign_address = address(this);
            
            emit CampaignCreation(address(this), creator, block.timestamp, goal, token);
    }
    
    function approveCrowdfunding() external returns(bool) {
        address tokenCrowdfunding = token;
        uint allowance = IERC20(tokenCrowdfunding).balanceOf(msg.sender);
        bool success = IERC20(tokenCrowdfunding).approve(address(msg.sender), allowance);
        return success;
    }



    function payCreator() override external onlyOwner() {
        require(block.timestamp > endTimestamp, "The campaign has not ended yet");
        require(totalBalance > 0, "totalBalance cannot be empty");
        creator.transfer(totalBalance);
        totalBalance = 0;
        emit CreatorPaid(msg.sender, totalBalance);
    }

    function participateInETH() payable public ETHOnly() verifyState(State.Fundraising) validAddress(msg.sender) returns(bool success) {
        require(msg.sender != creator, "[FORBIDDEN] The creator cannot fundraise his own campaign");
        require(block.timestamp >= startTimestamp, "The campaign has not started yet");
        require(msg.value > 0, "Amount cannot be less or equal to zero");
        if (block.timestamp > endTimestamp && goal < totalBalance) {
            state = State.Successfull;
            return false;
        }
        if (block.timestamp > endTimestamp && goal > totalBalance) {
                state = State.Successfull;
                return false;
        }
        //  adding the transaction value to the totalBalance
        totalBalance += msg.value;
        contributions[msg.sender] += msg.value;
        
        // Cashback : To Be Implemeted later
        // cbk.contribute(msg.sender, amount, token);
        
        // setting up the tiers for the transaction
        setTiers(msg.sender, msg.value);
        
        emit Participation(msg.sender, campaign_id, msg.value, totalBalance);
        return true;
    }


    function participateInERC20(uint256 amount) payable public ERC20Only() verifyState(State.Fundraising) validAddress(msg.sender) returns(bool success) {
            require(token != address(0), "[UNAUTHORIZED] This campaign can only be funded using the correct IERC20");
            require(msg.sender != creator, "[FORBIDDEN] The creator cannot fundraise his own campaign");
            require(block.timestamp >= startTimestamp, "The campaign has not started yet");
            require(amount > 0, "Amount cannot be less or equal to zero");
            if (block.timestamp > endTimestamp && goal < totalBalance) {
                state = State.Refund;
                return false;
            }
            if (block.timestamp > endTimestamp && goal > totalBalance) {
                state = State.Successfull;
                return false;
            }
            //  adding the transaction value to the totalBalance
            // [HLI] J'imagine que vous avez implémenté l'appele de "approve" dans votre UX
            require(IERC20(token).balanceOf(msg.sender) >= amount, "[FORBIDDEN] You don't have the funds for this transaction");
            IERC20(token).transferFrom(msg.sender, address(this), amount);
            totalBalance += amount;
            contributions[msg.sender] += amount;
            
            // cbk.contribute(msg.sender, amount, token);
            
            // setting up the tiers for the transaction
            setTiers(msg.sender, amount);
            
            emit Participation(msg.sender, campaign_id, amount, totalBalance);
            return true;
        }
    
    function refund() override external verifyState(State.Refund) onlyOwner() returns(bool) {
        require(msg.sender != creator, "No refund for the creator");
        require(contributions[msg.sender] > 0, "You have not participated in the campaign");
        // [HLI] Ici vous avez une vulnérabilité aux reentrancy attacks.
        // https://quantstamp.com/blog/what-is-a-re-entrancy-attack
        
        uint myContribution = contributions[msg.sender];
        contributions[msg.sender] = 0;
        
        payable(msg.sender).transfer(myContribution);

        emit Refund(msg.sender, contributions[msg.sender]);
        return(true);
    }

    // Send ether to the contract
    receive() override external payable {
        participateInETH();
    }

    // **************************** //
    // *   Internal Functions     * //
    // **************************** //

    function setTiers(address from, uint amount) internal {
        for (uint i = 0; i < nbTiers; i++) {
            if (amount == tiersList[i].price) {
                contributionsTiers[from] = i;
                SafeMath.sub(tiersList[i].quantity, 1);
            }
        }
    }

    function addTiersFromList(uint[] memory tList) internal {
        uint tempIndex;
        uint tempPrice;
        uint tempQuantity;
        for (uint j = 0; j < nbTiers; j++) {
            if (j % 3 == 0) { tempIndex = tList[j]; }
            if (j % 3 == 1) { tempPrice = tList[j]; }
            if (j % 3 == 2) { 
                tempQuantity = tList[j];
                addTiers(tempIndex, tempPrice, tempQuantity);
            }
        }
    }


    function addTiers(uint index, uint price, uint quantity) internal {
        Tiers memory newTier = Tiers(index, price, quantity);
        tiersList.push(newTier);
    }
    

}