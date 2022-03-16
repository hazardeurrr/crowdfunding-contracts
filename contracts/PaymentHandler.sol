pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract PaymentHandler is Context {

    using SafeERC20 for IERC20;
  
    address owner;

    constructor() {
        owner = msg.sender;
    }

    // **************************** //
    // *         Functions        * //
    // **************************** //
    

    function payInERC20(uint256 amount, address userAddr, address campaign) payable public {
        IERC20(token).transferFrom(userAddr, campaign, amount);
    }


}