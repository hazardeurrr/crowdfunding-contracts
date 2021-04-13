pragma solidity ^0.8.0;

contract CrowdFundFactory {

    address[]  public allCrowdFund;

    function allCrowdfund() external view returns(uint) {
        return allCrowdFund.lenght;
    }

    function createCrowdFund() public {
        
    }
}