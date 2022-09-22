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
    uint public goal;
    uint256 public raised;
    address payable public creator;
    address public campaign_address;
    address public token;  // address of the token used as currency (or address(0) if ETH/BNB is used)
    address public BBSTAddr = address(0x000000000000000000000000000000000000dEaD); // Address of the BBST Token

    // Starting and ending date for the campaign
    uint public startTimestamp;
    uint public endTimestamp;

    // Starting block of the campaign
    uint public creationBlock;

    // Array representing the minimum value required for each tier
    uint256[] public amounts;
    // Array representing the number of plans available for each tier. -1 <=> unlimited
    int256[] public stock;


    constructor() {
        owner = msg.sender;
        creationBlock = block.number;
    }

    // **************************** //
    // *         Modifiers        * //
    // **************************** //

    modifier onlyOwner() {
        require(owner == _msgSender(), "You are not the Owner");
        _;
    }
    
    modifier onlyFactory() {
        require(0x49437Ec2ab67bC08dFf6d46ef51EDd7d134EdFE0 == _msgSender(), "You are not the Factory");
        _;
    }
    
    modifier onlyCreator() {
        require(creator == _msgSender(), "You are not the Creator of the campaign");
        _;
    }

    // **************************** //
    // *         Setters          * //
    // **************************** //

    function setBBSTAddr(address addr) external onlyOwner() {
        BBSTAddr = address(addr);
    }


    // **************************** //
    // *         Functions        * //
    // **************************** //


    //Initalize the campaign. Only callable by the factory
    function initialize(
        address payable creator_,
        uint campaign_id_,
        uint goal_, 
        uint startTimestamp_,
        uint endTimestamp_, 
        address token_,
        uint256[] memory amounts_,
        int256[] memory stock_
        ) onlyFactory() override external {
            creator = creator_;
            campaign_id = campaign_id_;
            goal = goal_;
            startTimestamp = startTimestamp_;
            endTimestamp = endTimestamp_;
            raised = 0;
            amounts = amounts_;
            stock = stock_;
            token = token_;
            campaign_address = address(this);
            
            emit CampaignCreation(address(this), creator, block.timestamp, goal, token);
    }

    // to change the owner of the contract
    function changeOwner(address newOwner) public onlyOwner() {
        owner = newOwner;
    }


    //Function used to pay the creator, i.e. transfers the balance from the contract to its address. This is for ETH campaigns only.
    function payCreator() override external onlyCreator() {
        require(block.timestamp > endTimestamp, "The campaign has not ended yet");
        require(address(this).balance > 0, "Contract balance cannot be empty");

        //To keep track of the total amount raised, we store it in a new field before processing the transfer. It will be used on our UI only.
        raised = address(this).balance;

        //fees : we take 2.5% of the total balance
        uint256 feeAmt =  (address(this).balance * 25) / 1000;
        uint256 totalForCreator =  address(this).balance - feeAmt;
        //Transfer fees to our address
        payable(0xdf823e818D0b16e643A5E182034a24905d38491f).transfer(feeAmt);
        //Transfer the rest to the creator
        creator.transfer(totalForCreator);
        
        emit CreatorPaid(msg.sender, totalForCreator);
    }

    //Same function, but for campaigns using ERC20
    function payCreatorERC20() override external onlyCreator() {
        require(block.timestamp > endTimestamp, "The campaign has not ended yet");
        require(IERC20(token).balanceOf(address(this)) > 0, "Contract balance cannot be empty");

        address bbstAddress = BBSTAddr;

        uint256 totalBalance = IERC20(token).balanceOf(address(this));
        raised = totalBalance;

        // If the currency used is BBST, we don't charge any fee
        if(token == bbstAddress){
            IERC20(token).transfer(creator, totalBalance);
        } else {
          uint256 feeAmt = (totalBalance * 25) / 1000;
            uint256 totalForCreator = totalBalance - feeAmt;
            IERC20(token).transfer(payable(0xdf823e818D0b16e643A5E182034a24905d38491f), feeAmt);
            IERC20(token).transfer(creator, totalForCreator);
        }
        
        emit CreatorPaid(msg.sender, totalBalance);
    }

    //Function called to donate to a campaign in ETH
    function participateInETH(uint indexTier) payable public returns(bool success) {
        require(block.timestamp >= startTimestamp, "The campaign has not started yet");
        require(block.timestamp < endTimestamp, "The campaign is finished");
        require(msg.value >= amounts[indexTier], "Amount is not correct");
        require(stock[indexTier] == -1 || stock[indexTier] > 0, "No stock left");
        
        if(stock[indexTier] != -1){     // <=> this tier has a limited quantity
            stock[indexTier] = stock[indexTier] - 1;
        }  
        //Call the participated function of the Reward contract
        Reward(0x77bD27b96635853E21C9Dfbf922b671eD914e44B).participate(msg.sender, msg.value, token);
        
        emit Participation(msg.sender, msg.value, address(this), indexTier);
        return true;
    }
    

    //Same for ERC20 campaigns
    function participateInERC20(uint indexTier, uint256 amount) payable public returns(bool success) {
        require(block.timestamp >= startTimestamp, "The campaign has not started yet");
        require(block.timestamp < endTimestamp, "The campaign is finished");
        require(amount >= amounts[indexTier], "Amount is not correct");
        require(stock[indexTier] == -1 || stock[indexTier] > 0, "No stock left");
        

        //Calls PaymentHandler with the corresponding data. We delegate the process to this contract to prevent multiple allowance checks
        PaymentHandler(0x031865572E39441a58e7C7423EC52E3DbFb1E555).payInERC20(amount, msg.sender, address(this), token);
        Reward(0x77bD27b96635853E21C9Dfbf922b671eD914e44B).participate(msg.sender, amount, token);

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
    // *   Internal Functions     * //
    // **************************** //

    function getStock() public view returns (int256[] memory) {
        return stock;
    }
}