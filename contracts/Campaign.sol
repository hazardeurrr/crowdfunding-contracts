pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./ICampaign.sol";
import "./PaymentHandler.sol";
import "./Reward.sol";

contract Campaign is ICampaign, Context {

    using SafeERC20 for IERC20;
   // address factory;
    address owner;
    
    // General information about the campaign
    uint public campaign_id;
    address payable public creator;
    address public campaign_address;
    address public token;  // address of the token used as currency (or address(0) if ETH/BNB is used)
    address public BBSTAddr = address(0x000000000000000000000000000000000000dEaD); // Address of the BBST Token
    address payable public feesAddress = payable(0x0eEB242203a61b57d57eb8d3f9E3ce766B4dA69C); // fees Address
    uint public baseFeeRate;
    uint public bbstFeeRate;
    // Starting block of the campaign
    uint public creationBlock;

    // Array representing the minimum value required for each tier
    uint256[] public amounts;
    // Array representing the number of plans available for each tier. -1 <=> unlimited
    int256[] public stock;


    constructor() {
        owner = msg.sender;
    }

    // **************************** //
    // *         Modifiers        * //
    // **************************** //

    modifier onlyOwner() {
        require(owner == _msgSender(), "You are not the Owner");
        _;
    }
    
    modifier onlyFactory() {
        require(0xb1e8cd0C5e49D735Cb59F938087A71C0248D7010 == _msgSender(), "You are not the Factory");
        _;
    }
    
    modifier onlyCreator() {
        require(creator == _msgSender(), "You are not the Creator of the campaign");
        _;
    }

    // **************************** //
    // *         Functions        * //
    // **************************** //


    //Initalize the campaign. Only callable by the factory
    function initialize(
        address payable creator_,
        uint campaign_id_,
        address token_,
        address bbstAdr_,
        address feesAddr_,
        uint256[] memory amounts_,
        int256[] memory stock_,
        uint baseFeeRate_,
        uint bbstFeeRate_
        ) onlyFactory() override external {
            creator = creator_;
            campaign_id = campaign_id_;
            amounts = amounts_;
            stock = stock_;
            token = token_;
            campaign_address = address(this);
            creationBlock = block.number;
            BBSTAddr = bbstAdr_;
            feesAddress = payable(feesAddr_);
            baseFeeRate = baseFeeRate_;
            bbstFeeRate = bbstFeeRate_;
            
            emit CampaignCreation(address(this), creator, block.timestamp, token);
    }

    // to change the owner of the contract
    function changeOwner(address newOwner) public onlyOwner() {
        owner = newOwner;
    }


    //Function used to pay the creator, i.e. transfers the balance from the contract to its address. This is for ETH campaigns only.
    function payCreator() override external onlyCreator() {
        require(address(this).balance > 0, "Contract balance cannot be empty");

        uint256 totalBalance = address(this).balance;

        //fees : we take 3.5% of the total balance
        uint256 feeAmt =  (totalBalance * baseFeeRate) / 1000;
        uint256 totalForCreator =  totalBalance - feeAmt;
        //Transfer fees to our address
        payable(feesAddress).transfer(feeAmt);
        //Transfer the rest to the creator
        creator.transfer(totalForCreator);
        emit CreatorPaid(msg.sender, totalForCreator);
    }

    //Same function, but for campaigns using ERC20
    function payCreatorERC20() override external onlyCreator() {
        require(IERC20(token).balanceOf(address(this)) > 0, "Contract balance cannot be empty");

        address bbstAddress = BBSTAddr;

        uint256 totalBalance = IERC20(token).balanceOf(address(this));

        // If the currency used is BBST, we don't charge any fee
        uint feeRate = baseFeeRate;
        if(token == bbstAddress){
           feeRate = bbstFeeRate;
        }

        uint256 feeAmt = (totalBalance * feeRate) / 1000;
        uint256 totalForCreator = totalBalance - feeAmt;
        IERC20(token).transfer(payable(feesAddress), feeAmt);
        IERC20(token).transfer(creator, totalForCreator);
        emit CreatorPaid(msg.sender, totalForCreator);
    }

    //Function called to donate to a campaign in ETH
    function participateInETH(uint indexTier) payable public returns(bool success) {
        require(msg.value >= amounts[indexTier], "Amount is not correct");
        require(stock[indexTier] == -1 || stock[indexTier] > 0, "No stock left");
        
        if(stock[indexTier] != -1){     // <=> this tier has a limited quantity
            stock[indexTier] = stock[indexTier] - 1;
        }  

        emit Participation(msg.sender, msg.value, address(this), indexTier);
        return true;
    }
    

    //Same for ERC20 campaigns
    function participateInERC20(uint indexTier, uint256 amount) payable public returns(bool success) {
        require(amount >= amounts[indexTier], "Amount is not correct");
        require(stock[indexTier] == -1 || stock[indexTier] > 0, "No stock left");

        //Calls PaymentHandler with the corresponding data. We delegate the process to this contract to prevent multiple allowance checks
        PaymentHandler(0x8BdCf141A050078E528afC6a095Db409C90948B1).payInERC20(amount, msg.sender, address(this), token);

        if(stock[indexTier] != -1){
            stock[indexTier] = stock[indexTier] - 1;
        }
    
        emit Participation(msg.sender, amount, address(this), indexTier);
        return true;
    }
        
   
    // Send ether to the contract
    receive() override external payable {
        // participateInETH();
    }

    // **************************** //
    // *         GETTERS          * //
    // **************************** //

    function getStock() public view returns (int256[] memory) {
        return stock;
    }
}