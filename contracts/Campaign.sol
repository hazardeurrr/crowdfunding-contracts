pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./ICampaign.sol";
import "./ERC20Payment.sol";
import "./Reward.sol";

contract Campaign is ICampaign, Context {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address factory;
    
    // General information about the campaign
    uint public campaign_id;
    address payable public creator;
    uint public goal;
    uint256 public totalBalance;
    uint256 public raised;
    address public campaign_address;
    address private token;

    address owner;

    address payable feesReceiver = payable(0x4f4A40B732A8D6e87CbC720142ad63Dc9D828139);

    // Starting and ending date for the campaign
    uint public startTimestamp;
    uint public endTimestamp;

    mapping(address => uint) public contributions;

    struct Subscriber {
        address addr;
        uint tier;
    }

    uint256[] public amounts;
    int256[] public stock;


    constructor() {
        owner = msg.sender;
    }

    Subscriber[] public subscribers;

    // **************************** //
    // *         Modifiers        * //
    // **************************** //


    modifier validAddress(address from) {
        require(from != address(0), "Cannot be the address(0)");
        _;
    }

    modifier validAmount(uint amount_) {
        require(amount_ > 0, "Amount cannot be equal or less than 0");
        _;
    }

    modifier ETHOnly() {
        require(token == address(address(0)), "[WARNING] This campaign only receives ETH");
        _;
    }

    modifier ERC20Only() {
        require(token != address(address(0)), "[WARNING] This campaign only receives ERC20");
        _;
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "You are not the Owner");
        _;
    }
    
    modifier onlyFactory() {
        require(factory == _msgSender(), "You are not the Factory");
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
        ) override external {
            creator = creator_;
            campaign_id = campaign_id_;
            goal = goal_;
            startTimestamp = startTimestamp_;
            endTimestamp = endTimestamp_;
            totalBalance = 0;
            raised = totalBalance;
            amounts = amounts_;
            stock = stock_;
            token = token_;
            campaign_address = address(this);
            
            emit CampaignCreation(address(this), creator, block.timestamp, goal, token);
    }
    
    // check if possible
    //function approveCrowdfunding(address userAddr) external returns(bool) {
        // address tokenCrowdfunding = token;
        // uint256 INFINITE = 2**256 - 1;
        // bool success = IERC20(tokenCrowdfunding).approve(address(userAddr), INFINITE);
        // return success;
    //}


    function payCreator() override external onlyCreator() {
        require(block.timestamp > endTimestamp, "The campaign has not ended yet");
        require(address(this).balance > 0, "Contract balance cannot be empty");   // ????

        raised = address(this).balance;

        //fees
        uint256 feeAmt =  address(this).balance.mul(25).div(1000);
        uint256 totalForCreator =  address(this).balance.sub(feeAmt);
        payable(0xdf823e818D0b16e643A5E182034a24905d38491f).transfer(feeAmt);
        creator.transfer(totalForCreator);
        
        emit CreatorPaid(msg.sender, totalForCreator);
    }

    function payCreatorERC20() override external onlyCreator() {
        require(block.timestamp > endTimestamp, "The campaign has not ended yet");
        require(IERC20(token).balanceOf(address(this)) > 0, "Contract balance cannot be empty");    // ????

        address bbstAddress = address(0x67c0fd5c30C39d80A7Af17409eD8074734eDAE55);
        uint256 totalBalance = IERC20(token).balanceOf(address(this));


        if(token == bbstAddress){
            //fees
            IERC20(token).transfer(creator, totalBalance);
        } else {
          uint256 feeAmt = totalBalance.mul(25).div(1000);
            uint256 totalForCreator = totalBalance.sub(feeAmt);
            IERC20(token).transfer(payable(0xdf823e818D0b16e643A5E182034a24905d38491f), feeAmt);
            IERC20(token).transfer(creator, totalForCreator);
        }
        
        emit CreatorPaid(msg.sender, totalBalance);
    }


    function participateInETH(uint indexTier) payable public ETHOnly() validAddress(msg.sender) returns(bool success) {
        require(block.timestamp >= startTimestamp, "The campaign has not started yet");
        require(block.timestamp < endTimestamp, "The campaign is finished");
        require(msg.value >= amounts[indexTier], "Amount is not correct");
        require(stock[indexTier] == -1 || stock[indexTier] > 0, "No stock left");
        
        if(stock[indexTier] != -1){
            stock[indexTier] = stock[indexTier] - 1;
        }  
        
        emit Participation(msg.sender, msg.value, address(this), indexTier);
        return true;
    }

    function participateInERC20(uint indexTier, uint256 amount) payable public ERC20Only() validAddress(msg.sender) returns(bool success) {
        require(block.timestamp >= startTimestamp, "The campaign has not started yet");
        require(block.timestamp < endTimestamp, "The campaign is finished");
        require(amount >= amounts[indexTier], "Amount is not correct");
        require(stock[indexTier] == -1 || stock[indexTier] > 0, "No stock left");
        

        // appeler ERC20 PAYMENT
        ERC20Payment(0x4FbcC5abC094badb24F6555D140c75bC55221Fb5).payInERC20(amount, msg.sender, address(this), token);   // changer par la bonne addresse une fois le contrat déployé

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


    function isCreator() public view returns(bool) {
        require(msg.sender == creator, "You are not the creator of this campaign");
        return true;
    }


    // **************************** //
    // *   Internal Functions     * //
    // **************************** //

    function getStock() public view returns (int256[] memory) {
        return stock;
    }

    function getSubs() public view returns (Subscriber[] memory) {
        return subscribers;
    }

}