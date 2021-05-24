pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';


contract Campaign {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    enum State {
        Fundraising,
        Successfull,
        Expired
    }

    

    // General information about the campaign
    uint public campaign_id;
    address payable public creator;
    uint public goal;
    uint256 public totalBalance;
    State public state;
    address public owner;
    address public campaign_address;
    bool public partialGoal;
    IERC20 private token;

    // Starting and ending date for the campaign
    uint public startTimestamp;
    uint public endTimestamp;

    // Tiers
    uint nbTiers;
    [[uint, uint]] tiers;

    mapping(address => uint) public contributions;
    mapping(address => uint) public contributionsTiers;

    // **************************** //
    // *         Events           * //
    // **************************** //
    event CampaignCreated(address creator, uint timestamp, uint goal);

    // Participation from an address
    event Participation(address from, uint campaign_id, uint amount, uint totalBalance);

    // Event triggered when the creator has been paid
    event CreatorPaid(address creator, uint total_amount);

    event Refund(address from, uint refundAmount);
    

    // **************************** //
    // *         Modifiers        * //
    // **************************** //

    modifier changeState(State state_) {
        require(state != state_, 'State must be different');
        state = state_;
        _;
    }

    modifier verifyState(State state_) {
        require(state == state_, 'State must be the same');
        _;
    }

    modifier validAddress(address from) {
        require(from != address(0), 'Cannot be the address(0)');
        _;
    }

    modifier validAmount(uint amount_) {
        require(amount_ > 0, 'Amount cannot be equal or less than 0');
        _;
    }

    modifier verifyOwner(address owner_) {
        require(msg.sender == owner_, '[FORBIDDEN] You are not the owner of the campaign');
        _;
    }

    constructor(
        address payable creator_,
        uint campaign_id_,
        uint goal_,
        uint startTimestamp_,
        uint endTimestamp_,
        bool partialGoal_,
        uint nbTiers_,
        IERC20 token_,
        [uint, uint}] memory tiers_
        ) {
            creator = creator_;
            campaign_id = campaign_id_;
            goal = goal_;
            startTimestamp = startTimestamp_;
            endTimestamp = endTimestamp_;
            state = State.Fundraising;
            owner = creator;
            totalBalance = 0;
            partialGoal = partialGoal_;
            require(tiers_.length == nbTiers_, 'Numbers of tiers dont match the tiers list length');
            nbTiers = nbTiers_;
            tiers = tiers_;
            token = token_;
            campaign_address = address(this);
            emit CampaignCreated(creator, block.timestamp, goal);
    }

    function payCreator() public verifyOwner(msg.sender) {
        require(block.timestamp > endTimestamp, 'The campaign has not ended yet');
        require(totalBalance > 0, 'totalBalance cannot be empty');
        creator.transfer(totalBalance);
        totalBalance = 0;
        emit CreatorPaid(msg.sender, totalBalance);
    }

    function participate() payable public verifyState(State.Fundraising) validAddress(msg.sender) returns(bool success) {
        require(msg.sender != creator, '[FORBIDDEN] The creator cannot fundraise his own campaign');
        require(block.timestamp >= startTimestamp, 'The campaign has not started yet');
        require(msg.value > 0, 'Amount cannot be less or equal to zero');
        if (block.timestamp > endTimestamp) {
            state = State.Expired;
            revert();
        }
        //  adding the transaction value to the totalBalance
        totalBalance += msg.value;
        contributions[msg.sender] += msg.value;
        
        // setting up the tiers for the transaction
        setTiers(msg.sender, msg.value);
        
        emit Participation(msg.sender, campaign_id, msg.value, totalBalance);
        return true;
    }

    function getRefund() public verifyState(State.Expired) {
        require(msg.sender != creator, 'No refund for the creator');
        require(contributions[msg.sender] > 0, 'You have not participated in the campaign');
        payable(msg.sender).transfer(contributions[msg.sender]);
        contributions[msg.sender] = 0;
        emit Refund(msg.sender, contributions[msg.sender]);
    }

    // Send ether to the contract
    receive() external payable {
        participate();
    }

    /**
        Internal function
     */

    function setTiers(address from, uint amount) internal {
        for (uint i = 0; i < nbTiers; i++) {
            if (amount == tiers[i][0]) {
                contributionsTiers[from] = i;
                SafeMath.sub(tiers[i][1], 1)
            }
        }
    }
    

}