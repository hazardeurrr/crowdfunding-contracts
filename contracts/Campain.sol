pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract Campain {

    using SafeMath for uint256;

    enum State {
        Fundraising,
        Successfull,
        Expired
    }

    // General information about the campain
    uint public campain_id;
    address payable public creator;
    uint public goal;
    uint256 public balance;
    State public state;
    address public owner;
    bool public partialGoal;

    // Starting and ending date for the campain
    uint public startTimestamp;
    uint public endTimestamp;

    // Tiers
    uint nbTiers;
    uint[] tiers;

    mapping(address => uint) public contributions;
    mapping(address => uint) public contributionsTiers;

    event CampainCreated(address creator, uint timestamp, uint goal);

    // Participation from an address
    event Participation(address from, uint campain_id, uint amount, uint balance);

    // Event triggered when the creator has been paid
    event CreatorPaid(address creator, uint total_amount);

    event Refund(address from, uint refundAmount);

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
        require(msg.sender == owner_, '[FORBIDDEN] You are not the owner of the campain');
        _;
    }

    constructor(
        address payable creator_,
        uint campain_id_,
        uint goal_,
        uint startTimestamp_,
        uint endTimestamp_,
        bool partialGoal_,
        uint nbTiers_,
        uint[] memory tiers_
        ) {
            creator = creator_;
            campain_id = campain_id_;
            goal = goal_;
            startTimestamp = startTimestamp_;
            endTimestamp = endTimestamp_;
            state = State.Fundraising;
            owner = creator;
            balance = 0;
            partialGoal = partialGoal_;
            require(tiers_.length == nbTiers_, 'Numbers of tiers dont match the tiers list');
            nbTiers = nbTiers_;
            tiers = tiers_;
            emit CampainCreated(creator, block.timestamp, goal);
    }

    function payCreator() public verifyOwner(msg.sender) {
        require(block.timestamp > endTimestamp, 'The campain has not ended yet');
        require(balance > 0, 'Balance cannot be empty');
        creator.transfer(balance);
        balance = 0;
        emit CreatorPaid(msg.sender, balance);
    }

    function participate() payable external verifyState(State.Fundraising) validAddress(msg.sender) returns(bool success) {
        require(msg.sender != creator, '[FORBIDDEN] The creator cannot fundraise his own campain');
        require(block.timestamp >= startTimestamp, 'The campain has not started yet');
        require(msg.value > 0, 'Amount cannot be less or equal to zero');
        if (block.timestamp > endTimestamp) {
            state = State.Expired;
            revert();
        }

        //  adding the transaction value to the balance
        balance += msg.value;
        contributions[msg.sender] += msg.value;
        
        // setting up the tiers for the transaction
        setTiers(msg.sender, msg.value);
        
        emit Participation(msg.sender, campain_id, msg.value, balance);
        return true;
    }

    function getRefund() public verifyState(State.Expired) {
        require(msg.sender != creator, 'No refund for the creator');
        require(contributions[msg.sender] > 0, 'You have not participated in the campain');
        payable(msg.sender).transfer(contributions[msg.sender]);
        emit Refund(msg.sender, contributions[msg.sender]);
    }

    receive() external payable {
        revert();
    }

    /**
        Internal function
     */

    function setTiers(address from, uint amount) internal {
        for (uint i = nbTiers; i > 0; i--) {
            if (amount >= tiers[i]) {
                contributionsTiers[from] = i;
            }
        }
    }
    

}