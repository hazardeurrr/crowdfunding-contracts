pragma solidity ^0.8.0;

import './BlockBoosted.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';


contract ICO {

    mapping(address => uint) public balance;
    uint256 public tokenSold;
    address public creator;
    BlockBoosted blockboosted;
    uint256 start_time;

    constructor(uint256 _start_time) {
        creator = msg.sender;
        tokenSold = 0;
        start_time = _start_time;
    } 

    modifier StartTime() {
        require(block.timestamp > start_time,'Not started');
        _;
    }

    receive() external payable StartTime() {
    }


    function buyToken(uint _amount) payable public StartTime() returns(bool) {
        require(msg.value > 0, 'Amount must be greater than 0');
        balance[msg.sender] = SafeMath.add(balance[msg.sender], msg.value);
        blockboosted.transferFrom(address(this), msg.sender, _amount);
        tokenSold = SafeMath.add(tokenSold, _amount);
        return true;
    }
}