pragma solidity ^0.8.0;

import './CrowdFund.sol';

contract CrowdFundFactory {

    mapping(address => CrowdFund) public campains;
    address[]  public allCrowdFund;

    // should return allCrowdFund.length
    function allCrowdfund() external view returns(uint) {
        
    }

    // Allow a creator to instantiate a CrowFund and start a campain
    function createCrowdFund(
        uint timestamp, uint goal, 
        uint[] memory tiersStage, 
        uint8 nbTiers, 
        uint endDate) 
        public {
        new CrowdFund(timestamp, goal, tiersStage, nbTiers, endDate );
    }   
}