pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

// ERC 20 Inheritance
contract BlockBoosted is ERC20 {
    using SafeMath for uint256;
    uint256 public _totalSupply;


    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() ERC20('BlockBoosted', 'BBST'){
        
        _totalSupply = 20000000;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

}