pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract ERC20Payment is Context {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    

  
    address owner;

    constructor() {
        owner = msg.sender;
    }


    // **************************** //
    // *         Functions        * //
    // **************************** //
    
    // check if possible
    function approveCrowdfunding(address userAddr, address token) external returns(bool) {
        address tokenCrowdfunding = token;
        uint256 INFINITE = 2**256 - 1;
        bool success = IERC20(tokenCrowdfunding).approve(userAddr, INFINITE);
        return success;
    }

    function amountAllowance(address userAddr, address token) public view returns(uint){
        return IERC20(token).allowance(address(this), userAddr) ;
    }

    // function checkAllowance(address userAddr, uint amount) external returns(bool) {
    //   if(token.allowance(userAddr, address(this)) > amount) {
    //     return true
    //   }
    //   else
    //     approveCrowdfunding(userAddr);
    // }

    function payInERC20(uint256 amount, address userAddr, address campaign, address token) payable public {
        
        //  adding the transaction value to the totalBalance
        IERC20(token).transferFrom(userAddr, campaign, amount);
        // IERC20(token).transfer(, amount);
        

    }

    // **************************** //
    // *   Internal Functions     * //
    // **************************** //


}