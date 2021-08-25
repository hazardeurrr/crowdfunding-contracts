pragma solidity ^0.8.0;

import './BlockBoosted.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';


contract ICO {

    mapping(address => uint) public balance;
    uint256 public tokenSold;
    address public creator;
    BlockBoosted blockboosted;
    uint256 start_time;

    uint256 private ratio;
    uint private threshold;
    event TokenBought(address buyer, uint amountInETH, uint amountInBBST);

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
        buyToken();
    }

    /**
        This function sends BBST in exchange of ETH
        ratio : multiplier for increasing the price of BBST against ETH
        threshold : to be set, once triggered the ratio changes
     */
    function buyToken() payable public StartTime() returns(bool success) {
        require(msg.value > 0, 'Amount must be greater than 0');
        uint256 amount = SafeMath.mul(uint(ratio), msg.value);
        balance[msg.sender] = SafeMath.add(balance[msg.sender], amount);
        blockboosted.transferFrom(address(this), msg.sender, amount);
        tokenSold = SafeMath.add(tokenSold, amount);
        emit TokenBought(msg.sender, amount, block.timestamp);
        if (tokenSold > threshold) {
            // Create the function to reduce gradually the number of BBST sent against ETH
            // during ICO. DO NOT FORGET that the ETH price is in wei (10**18)
            // ratio = 
        }
        return true;
    }
}