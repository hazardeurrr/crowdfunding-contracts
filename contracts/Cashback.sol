pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './Blockboosted.sol'
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract Cashback {

    using SafeMath for uint;

    uint public counter;
    uint public weeklySupply;
    uint public nbWeeks;
    
    // priceBBST
    // priceETH
    // priceUSDT
    // poidsBBST
    // poidsETH
    // poidsUSDT

    // Une fois par semaine appel de l'oracle
    // set des prices

    mapping(address => uint) public balancesToBeClaimed;
    mapping(address => uint) public totalTransactionWeekly;
    BlockBoosted bbst;
    constructor() {
      counter = 7000000;
      weeklySupply = 30000;
      nbWeeks = 0;
    }

    function contribute(address contibutor, uint amount, IERC20 token) public {
      /* if(token == BBST)
          updateCashbackByAddress(contributor, amount * priceBBST * poidsBBST)
        else if (token == ETH)
          updateCashbackByAddress(contributor, amount * priceETH * poidsETH)
        else
          updateCashbackByAddress(contributor, amount * poidsUSDT)


      */
    }

    //function called everyweek to distribute the tokens (update the "balancesToBeClaimed" mapping)
    function updateWeeklyBalances() public {
      //check the number of Weeks and distribute over the address of totalTransactionWeekly + decrease the total counter of tokens

      /*
        total = totalTransactionWeekly.values.sum()
        foreach(address in totalTransactionWeekly){
          balancesToBeClaimed[address] += (totalTransactionWeekly[address] / total) * weeklySupply
        }

        counter -= weeklySupply
        updateWeeklySupply()
      */

    }
    
    function claimToken() payable public {
      /*
      if(balancesToBeClaimed[msg.sender] != 0)
        transfer(to: msg.sender, amount: balancesToBeClaimed[msg.sender])
      */
    }

    function updateCashbackByAddress(address sender, uint amount) public {
      totalTransactionWeeekly[sender] += amount;
    }
}