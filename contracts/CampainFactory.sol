pragma solidity ^0.8.0;

import './Campain.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';


contract CampainFactory {

    using SafeMath for uint;

    mapping(address => Campain) public campains;
    address[]  public allCrowdFund;

    uint256 public nbCampain;
    Campain private newCampain;
    
    event CampainCreated(address creator, uint nbCampain, uint goal);

    constructor() {
        nbCampain = 0;
    }

    function createCampain(
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
        newCampain = new Campain(payable(msg.sender), nbCampain, goal_, startTimestamp_, endTimestamp_, partialGoal_, nbTiers_, listTiers_);
        campains[msg.sender] = newCampain;
        nbCampain += 1;
        emit CampainCreated(msg.sender, nbCampain, goal_);
        return true;
    }


}