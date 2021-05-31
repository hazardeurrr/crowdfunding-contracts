pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './Blockboosted.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract Cashback {

    using SafeMath for uint;

    uint public counter;
    uint public weeklySupply;
    uint public nbWeeks;
    uint public totalOfWeek;
    
    uint public priceBBST;
    uint public priceETH;
    uint public priceUSDT;
    uint public poidsBBST;
    uint public poidsETH;
    uint public poidsUSDT;

    // Une fois par semaine appel de l'oracle
    // set des prices

    mapping(address => uint) public balancesToBeClaimed;
    mapping(address => uint) public totalTransactionWeekly;
    address[] public listClaimers;
    BlockBoosted bbst;

    constructor() {
      counter = 7000000;
      weeklySupply = 30000;
      nbWeeks = 0;
      totalOfWeek = 0;
    }

    function contribute(address contributor, uint amount, IERC20 token) public {
        if (token == BBST) {
          updateCashbackByAddress(contributor, amount * priceBBST * poidsBBST);
        }
        else if (token == ETH) {
          updateCashbackByAddress(contributor, amount * priceETH * poidsETH);
        }
        else {
          updateCashbackByAddress(contributor, amount * poidsUSDT);
        }

      /*
      */
    }

    //function called everyweek to distribute the tokens (update the "balancesToBeClaimed" mapping)
    function updateWeeklyBalances() public {
      //check the number of Weeks and distribute over the address of totalTransactionWeekly + decrease the total counter of tokens
      // check the number of BBST tokens distributed doesn't exceed 35% of the transactions done on the protocol this week

        uint toBeDistributed = weeklySupply;

        if (totalOfWeek * 0.35 > weeklySupply * priceBBST){
          toBeDistributed = (totalOfWeek * 0.35) / priceBBST;
          //add weeklySupply - toBeDistributed to next week supply ? Or send to community fund.
        }

        for (uint i = 0; i < listClaimers.length(); i++) {
          address addr = listClaimers[i];

          balancesToBeClaimed[addr] += (totalTransactionWeekly[addr] / totalOfWeek) * toBeDistributed;
        }

        // foreach(address in totalTransactionWeekly) {
        //   balancesToBeClaimed[address] += (totalTransactionWeekly[address] / totalOfWeek) * toBeDistributed
        // }

        counter -= weeklySupply;
        totalOfWeek = 0;
        // updateWeeklySupply()     // updateWeeklySupply(weeklySupply - toBeDistributed) pour ajouter le reste


    }
    
    function claimToken() payable public {
      /*
      if(balancesToBeClaimed[msg.sender] != 0)
        transfer(to: msg.sender, amount: balancesToBeClaimed[msg.sender])
      */
    }

    function updateCashbackByAddress(address sender, uint amount) public {
      totalTransactionWeekly[sender] += amount;

      if (listClaimers.length() == 0) {
        listClaimers.push(sender);
      }

      for (uint i=0; i < listClaimers.length(); i++) {
        if (listClaimers[i] != sender) {
          listClaimers.push(sender);
        }
      }

      totalOfWeek += amount;
    }
}