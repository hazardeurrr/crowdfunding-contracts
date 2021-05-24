pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './Blockboosted.sol'

contract Monitor {

    using SafeMath for uint;

    BlockBoosted private bbst;

    mapping(address => uint) transactions;
    mapping(address => Airdrop) airdrop;

    struct Aidrop {
        uint amount;
        uint reward;
    }

    address public creator;

    constructor() {
        creator = msg.sender;
    }

    function addTransaction() external payable {
        SafeMath.add(transactions[msg.sender], msg.value);
        SafeMath.add(airdrop[msg.sender].amount, msg.value);
    }

    function airdrop() {
        
    }

    // Internal Functions

    function calculateAirdrop(address from) internal {
        airdrop[from].reward = //Function here
    }
       
    
}