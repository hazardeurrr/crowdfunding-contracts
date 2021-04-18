pragma solidity ^0.8.0;

import './Campain.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';


contract CrowdFundFactory {


    mapping(address => Campain) public campains;
    address[]  public allCrowdFund;

    uint256 public nbCampain;

    constructor() {
        nbCampain = 0;
    }

    // should return allCrowdFund.length
    function allCrowdfund() external view returns(uint) {
        
    }

    // Allow a creator to instantiate a CrowFund and start a campain
    // function createCrowdFund(
    //     uint timestamp, uint goal, 
    //     uint[] memory tiersStage, 
    //     uint8 nbTiers, 
    //     uint endDate) 
    //     public {
    //     new Campain(timestamp, goal, tiersStage, nbTiers, endDate );
    //     SafeMath.add(nbCampain, 1);
    // }
}