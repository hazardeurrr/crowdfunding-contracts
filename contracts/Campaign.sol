pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';


contract Campaign {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    enum State {
        // Campaign has not started yet
        NotStarted,
        // Campaign is raising funds
        Fundraising,
        // Campaign reached its goal
        Successfull,
        // Campaign has not reached its goal
        Refund,
        // Campaign has been canceled
        Canceled
    }

    

    // General information about the campaign
    uint public campaign_id;
    address payable public creator;
    uint public goal;
    uint256 public totalBalance;
    State public state;
    address public owner;
    address public campaign_address;
    bool public partialGoal;
    IERC20 private token;
    uint nbTiers;

    // Starting and ending date for the campaign
    uint public startTimestamp;
    uint public endTimestamp;

    // Tiers
    struct Tiers {
        uint index;
        uint price;
        uint quantity;
    }
    Tiers[] public tiersList;

    mapping(address => uint) public contributions;
    mapping(address => uint) public contributionsTiers;

    // **************************** //
    // *         Events           * //
    // **************************** //
    event CampaignCreated(address creator, uint timestamp, uint goal, IERC20 token);

    // Participation from an address
    event Participation(address from, uint campaign_id, uint amount, uint totalBalance);

    // Event triggered when the creator has been paid
    event CreatorPaid(address creator, uint total_amount);

    event Refund(address from, uint refundAmount);
    

    // **************************** //
    // *         Modifiers        * //
    // **************************** //

    modifier changeState(State state_) {
        require(state != state_, 'State must be different');
        state = state_;
        _;
    }

    modifier verifyState(State state_) {
        require(state == state_, 'State must be the same');
        _;
    }

    modifier validAddress(address from) {
        require(from != address(0), 'Cannot be the address(0)');
        _;
    }

    modifier validAmount(uint amount_) {
        require(amount_ > 0, 'Amount cannot be equal or less than 0');
        _;
    }

    modifier verifyOwner(address owner_) {
        require(msg.sender == owner_, '[FORBIDDEN] You are not the owner of the campaign');
        _;
    }

    constructor(
        address payable creator_,
        uint campaign_id_,
        uint goal_,
        uint startTimestamp_,
        uint endTimestamp_,
        bool partialGoal_,
        IERC20 token_,
        uint nbTiers_,
        uint[] memory tiers_
        ) {
            creator = creator_;
            campaign_id = campaign_id_;
            goal = goal_;
            startTimestamp = startTimestamp_;
            endTimestamp = endTimestamp_;
            state = State.Fundraising;
            owner = creator;
            totalBalance = 0;
            partialGoal = partialGoal_;
            nbTiers = nbTiers_;
            addTiersFromList(tiers_);
            token = token_;
            campaign_address = address(this);
            emit CampaignCreated(creator, block.timestamp, goal, token);
    }


    function addTiers(uint index, uint price, uint quantity) public verifyOwner(msg.sender) {
        Tiers memory newTier = Tiers(index, price, quantity);
        tiersList.push(newTier);
    }

    function payCreator() public verifyOwner(msg.sender) {
        require(block.timestamp > endTimestamp, 'The campaign has not ended yet');
        require(totalBalance > 0, 'totalBalance cannot be empty');
        creator.transfer(totalBalance);
        totalBalance = 0;
        emit CreatorPaid(msg.sender, totalBalance);
    }

    function participateInETH() payable public verifyState(State.Fundraising) validAddress(msg.sender) returns(bool success) {
        require(msg.sender != creator, '[FORBIDDEN] The creator cannot fundraise his own campaign');
        require(block.timestamp >= startTimestamp, 'The campaign has not started yet');
        require(msg.value > 0, 'Amount cannot be less or equal to zero');
        if (block.timestamp > endTimestamp && goal > totalBalance) {
            state = State.Successfull;
            // [HLI] Ici je ne pense pas que ça fonctionne. Revert() va annuler l'ensemble de ce qui s'est passé dans la tx.
            // L'état du contrat reviendra à son état initial, et 'state' ne sera pas modifié.
            revert();
        }
        if (block.timestamp > endTimestamp && goal > totalBalance) {
                state = State.Successfull;
                // [HLI] Même remarque
                revert();
        }
        //  adding the transaction value to the totalBalance
        totalBalance += msg.value;
        contributions[msg.sender] += msg.value;
        
        // cbk.contribute(msg.sender, amount, token);
        
        // setting up the tiers for the transaction
        setTiers(msg.sender, msg.value);
        
        emit Participation(msg.sender, campaign_id, msg.value, totalBalance);
        return true;
    }


    function participateInERC20(uint256 amount) payable public verifyState(State.Fundraising) validAddress(msg.sender) returns(bool success) {
            require(msg.sender != creator, '[FORBIDDEN] The creator cannot fundraise his own campaign');
            require(block.timestamp >= startTimestamp, 'The campaign has not started yet');
            require(amount > 0, 'Amount cannot be less or equal to zero');
            if (block.timestamp > endTimestamp && goal > totalBalance) {
                state = State.Refund;
                // [HLI] Meme remarque que dans participateInETH()
                // Vous devriez peut être mettre ces fonctions dans une fonction de controle séparée pour ne pas dupliquer la logique
                revert();
            }
            if (block.timestamp > endTimestamp && goal > totalBalance) {
                state = State.Successfull;
                // [HLI] Pareil
                revert();
            }
            //  adding the transaction value to the totalBalance
            // [HLI] J'imagine que vous avez implémenté l'appele de "approve" dans votre UX
            require(token.balanceOf(msg.sender) >= amount, "[FORBIDDEN] You don't have the funds for this transaction");
            token.transferFrom(msg.sender, address(this), amount);
            totalBalance += amount;
            contributions[msg.sender] += amount;
            
            // cbk.contribute(msg.sender, amount, token);
            
            // setting up the tiers for the transaction
            setTiers(msg.sender, amount);
            
            emit Participation(msg.sender, campaign_id, amount, totalBalance);
            return true;
        }
    
    function refund() public verifyState(State.Refund) {
        require(msg.sender != creator, 'No refund for the creator');
        require(contributions[msg.sender] > 0, 'You have not participated in the campaign');
        // [HLI] Ici vous avez une vulnérabilité aux reentrancy attacks.
        // https://quantstamp.com/blog/what-is-a-re-entrancy-attack
        payable(msg.sender).transfer(contributions[msg.sender]);
        contributions[msg.sender] = 0;
        // Une proposition
        // uint myContribution = contributions[msg.sender];
        // contributions[msg.sender] = 0;
        // payable(msg.sender).transfer(myContribution);
        

        emit Refund(msg.sender, contributions[msg.sender]);
    }

    // Send ether to the contract
    receive() external payable {
        participateInETH();
    }

    // **************************** //
    // *   Internal Function      * //
    // **************************** //

    function setTiers(address from, uint amount) internal {
        for (uint i = 0; i < nbTiers; i++) {
            if (amount == tiersList[i].price) {
                contributionsTiers[from] = i;
                SafeMath.sub(tiersList[i].quantity, 1);
            }
        }
    }

    function addTiersFromList(uint[] memory tList) internal {
        uint tempIndex;
        uint tempPrice;
        uint tempQuantity;
        for (uint j = 0; j < nbTiers; j++) {
            if (j % 3 == 0) { tempIndex = tList[j]; }
            if (j % 3 == 1) { tempPrice = tList[j]; }
            if (j % 3 == 2) { 
                tempQuantity = tList[j];
                addTiers(tempIndex, tempPrice, tempQuantity);
            }
        }
    }
    

}