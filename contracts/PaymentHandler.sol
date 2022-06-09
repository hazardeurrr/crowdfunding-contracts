pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract PaymentHandler is Context {

    using SafeERC20 for IERC20;
  
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "You are not the Owner");
        _;
    }

    // **************************** //
    // *         Functions        * //
    // **************************** //
    
    // to change the owner of the contract
    function changeOwner(address newOwner) public onlyOwner() {
        owner = newOwner;
    } 

    // function handling payment in ERC20. Called when someones participate to a campaign in ERC20
    function payInERC20(uint256 amount, address userAddr, address campaign, address token) payable public {
        //checks the call comes from the "Campaign" instance
        require(msg.sender == campaign);
        IERC20(token).transferFrom(userAddr, campaign, amount);
    }


}