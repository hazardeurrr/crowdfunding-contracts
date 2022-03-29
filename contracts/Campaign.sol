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
    address private token;


    // Starting and ending date for the campaign
    uint public startTimestamp;
    uint public endTimestamp;

    uint256[] public amounts;
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
        require(0x0000000000000000000000000000000000000000 == _msgSender(), "You are not the Factory");
        _;
    }
    
    modifier onlyCreator() {
        require(creator == _msgSender(), "You are not the Creator of the campaign");
        _;
    }


    // **************************** //
    // *         Functions        * //
    // **************************** //


    // to be only executed by the factory, not working yet because of delegateCall to be investigated
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


    function payCreator() override external onlyCreator() {
        require(block.timestamp > endTimestamp, "The campaign has not ended yet");
        require(address(this).balance > 0, "Contract balance cannot be empty");   // ????

        raised = address(this).balance;

        //fees
        uint256 feeAmt =  (address(this).balance * 25) / 1000;
        uint256 totalForCreator =  address(this).balance - feeAmt;
        payable(0xdf823e818D0b16e643A5E182034a24905d38491f).transfer(feeAmt);
        creator.transfer(totalForCreator);
        
        emit CreatorPaid(msg.sender, totalForCreator);
    }

    function payCreatorERC20() override external onlyCreator() {
        require(block.timestamp > endTimestamp, "The campaign has not ended yet");
        require(IERC20(token).balanceOf(address(this)) > 0, "Contract balance cannot be empty");    // ????

        address bbstAddress = address(0x67c0fd5c30C39d80A7Af17409eD8074734eDAE55);
        uint256 totalBalance = IERC20(token).balanceOf(address(this));
        raised = totalBalance;


        if(token == bbstAddress){
            //fees
            IERC20(token).transfer(creator, totalBalance);
        } else {
          uint256 feeAmt = (totalBalance * 25) / 1000;
            uint256 totalForCreator = totalBalance - feeAmt;
            IERC20(token).transfer(payable(0xdf823e818D0b16e643A5E182034a24905d38491f), feeAmt);
            IERC20(token).transfer(creator, totalForCreator);
        }
        
        emit CreatorPaid(msg.sender, totalBalance);
    }


    function participateInETH(uint indexTier) payable public returns(bool success) {
        require(block.timestamp >= startTimestamp, "The campaign has not started yet");
        require(block.timestamp < endTimestamp, "The campaign is finished");
        require(msg.value >= amounts[indexTier], "Amount is not correct");
        require(stock[indexTier] == -1 || stock[indexTier] > 0, "No stock left");
        
        if(stock[indexTier] != -1){
            stock[indexTier] = stock[indexTier] - 1;
        }  
        Reward(0xea462Ef2A3c7f98129FEB2D21AE463109556D7dd).participate(msg.sender, msg.value, token);
        
        emit Participation(msg.sender, msg.value, address(this), indexTier);
        return true;
    }
    

    function participateInERC20(uint indexTier, uint256 amount) payable public returns(bool success) {
        require(block.timestamp >= startTimestamp, "The campaign has not started yet");
        require(block.timestamp < endTimestamp, "The campaign is finished");
        require(amount >= amounts[indexTier], "Amount is not correct");
        require(stock[indexTier] == -1 || stock[indexTier] > 0, "No stock left");
        

        // appeler ERC20 PAYMENT
        PaymentHandler(0x6E48cEC04a7371D263E36Ef2282760E6cA267eE9).payInERC20(amount, msg.sender, address(this), token);   // changer par la bonne addresse une fois le contrat déployé
        Reward(0xea462Ef2A3c7f98129FEB2D21AE463109556D7dd).participate(msg.sender, amount, token);

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