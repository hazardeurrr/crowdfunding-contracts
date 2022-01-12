pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

// ERC 20 Inheritance
contract BlockBoosted is ERC20 {
    using SafeMath for uint256;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(uint256 totalSupply_) ERC20('BlockBoosted', 'BBST'){
        
        _mint(address(msg.sender), totalSupply_);
    }

}