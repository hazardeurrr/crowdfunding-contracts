pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./ICampaign.sol";
import "./ERC20Payment.sol";

contract Campaign is ICampaign, Context {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    enum State {
        NotStarted,
        Fundraising,
        Successfull,
        Refund,
        Canceled
    }
    address factory;
    

    // General information about the campaign
    uint public campaign_id;
    address payable public creator;
    uint public goal;
    uint256 public totalBalance;
    uint256 public raised;
    State public state;
    address public campaign_address;
    bool public partialGoal;
    address private token;

    address owner;
    

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

    modifier changeState(State state_) {
        require(state != state_, "State must be different");
        state = state_;
        _;
    }

    modifier verifyState(State state_) {
        require(state == state_, "State must be the same");
        _;
    }

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
        bool partialGoal_,
        address token_,
        uint256[] memory amounts_,
        int256[] memory stock_
        ) override external {
            creator = creator_;
            campaign_id = campaign_id_;
            goal = goal_;
            startTimestamp = startTimestamp_;
            endTimestamp = endTimestamp_;
            state = State.Fundraising;
            totalBalance = 0;
            partialGoal = partialGoal_;
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
        require(totalBalance > 0, "totalBalance cannot be empty");
        require((goal <= totalBalance && !partialGoal) || partialGoal, "Can't withdraw funds");

        creator.transfer(totalBalance);
        totalBalance = 0;
        emit CreatorPaid(msg.sender, totalBalance);
    }

    function payCreatorERC20() override external onlyCreator() {
        require(block.timestamp > endTimestamp, "The campaign has not ended yet");
        require(totalBalance > 0, "totalBalance cannot be empty");
        require((goal <= totalBalance && !partialGoal) || partialGoal, "Can't withdraw funds");

        IERC20(token).transfer(creator, totalBalance);
        totalBalance = 0;
        emit CreatorPaid(msg.sender, totalBalance);
    }


    function participateInETH(uint indexTier) payable public ETHOnly() validAddress(msg.sender) returns(bool success) {
        require(msg.sender != creator, "[FORBIDDEN] The creator cannot fundraise his own campaign");
        require(block.timestamp >= startTimestamp, "The campaign has not started yet");
        require(block.timestamp < endTimestamp, "The campaign is finished");
        require(msg.value > 0 && msg.value >= amounts[indexTier], "Amount is not correct");
        require(stock[indexTier] == -1 || stock[indexTier] > 0, "No stock left");
        
        if(stock[indexTier] != -1){
            stock[indexTier] = stock[indexTier] - 1;
        }
        
        //  adding the transaction value to the totalBalance
        totalBalance += msg.value;
        raised = totalBalance;
        uint256 amount = msg.value;
        contributions[msg.sender] += amount;
        amount = 0;

        Subscriber memory sub;

        sub.addr = msg.sender;
        sub.tier = indexTier;

        subscribers.push(sub);
        // Cashback : To Be Implemeted later
        // cbk.contribute(msg.sender, amount, token);
        
        
        emit Participation(msg.sender, campaign_id, msg.value, totalBalance);
        return true;
    }


    function participateInERC20(uint indexTier, uint256 amount) payable public ERC20Only() validAddress(msg.sender) returns(bool success) {
            require(token != address(0), "[UNAUTHORIZED] This campaign can only be funded using the correct IERC20");
            require(msg.sender != creator, "[FORBIDDEN] The creator cannot fundraise his own campaign");
            require(block.timestamp >= startTimestamp, "The campaign has not started yet");
            require(amount > 0 && amount >= amounts[indexTier], "Amount is not correct");
            require(stock[indexTier] == -1 || stock[indexTier] > 0, "No stock left");
            require(IERC20(token).balanceOf(msg.sender) >= amount, "[FORBIDDEN] You don't have the funds for this transaction");
            

            // appeler ERC20 PAYMENT
            ERC20Payment(0x5D86406d77BA1b85184ECbA07cf5A5785702229D).payInERC20(amount, msg.sender, address(this), token);   // changer par la bonne addresse une fois le contrat déployé

            if(stock[indexTier] != -1){
                stock[indexTier] = stock[indexTier] - 1;
            }

            totalBalance += amount;
            raised = totalBalance;
            uint256 _amount = amount;
            contributions[msg.sender] += _amount;
            _amount = 0;

            Subscriber memory sub;

            sub.addr = msg.sender;
            sub.tier = indexTier;

            subscribers.push(sub);
            // to be coded 
            // cbk.contribute(msg.sender, amount, token);
            
            
            emit Participation(msg.sender, campaign_id, amount, totalBalance);
            return true;


        }
        
    function refund() public returns(bool) {
        require(msg.sender != creator, "No refund for the creator");
        require(!partialGoal && block.timestamp > endTimestamp, "Can't refund this type of campaign");
        require(contributions[msg.sender] > 0, "You have not participated in the campaign");
        // [HLI] Ici vous avez une vulnérabilité aux reentrancy attacks.
        // https://quantstamp.com/blog/what-is-a-re-entrancy-attack
        
        uint myContribution = contributions[msg.sender];
        contributions[msg.sender] = 0;
        
        payable(msg.sender).transfer(myContribution);

        emit Refund(msg.sender, contributions[msg.sender]);
        return(true);
    }

    function refundERC20() public returns(bool) {
        require(msg.sender != creator, "No refund for the creator");
        require(!partialGoal && block.timestamp > endTimestamp, "Can't refund this type of campaign");
        require(contributions[msg.sender] > 0, "You have not participated in the campaign");

        uint myContribution = contributions[msg.sender];
        contributions[msg.sender] = 0;
        
        IERC20(token).transfer(payable(msg.sender), myContribution);

        emit Refund(msg.sender, contributions[msg.sender]);
        return(true);
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