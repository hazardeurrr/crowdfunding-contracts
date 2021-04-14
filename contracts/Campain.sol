pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract Campain {

    using SafeMath for uint;

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

    // Starting and ending date for the campain
    uint public startTimestamp;
    uint public endTimestamp;

    mapping(address => uint) public contributions;

    // Participation from an address
    event Participation(address from, uint campain_id, uint amount, uint balance);

    // Event triggered when the creator has been paid
    event CreatorPaid(address creator, uint total_amount);

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
        uint endTimestamp_
        ) {
            creator = creator_;
            campain_id = campain_id_;
            goal = goal_;
            startTimestamp = startTimestamp_;
            endTimestamp = endTimestamp_;
            state = State.Fundraising;
    }

    function payCreator() public verifyState(State.Successfull) verifyOwner(msg.sender) {
        creator.transfer(balance);
        balance = 0;
        emit CreatorPaid(msg.sender, balance);
    }

    function participate() payable external verifyState(State.Fundraising) {
        require(msg.sender != creator, '[FORBIDDEN] The creator cannot fundraise his own campain');
        emit Participation(msg.sender, campain_id, msg.value, balance);
    }

    function 

}