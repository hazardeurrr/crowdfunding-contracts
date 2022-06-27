
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Reward is Context {

    address owner;
    address factory;    // address of the factory contract
    uint256 public rewardStartTimestamp;    // timestamp of the beginning of the reward system

    bool active;    // is the reward system active or not

    // event sent when a user donate to a campaign
    event Participate(address indexed user, uint timestamp, uint256 amount, address token);
    // event sent when a user claims his rewards
    event Claimed(address claimer, uint256 amount, uint256 timestamp);

    /*** addresses that are allowed to call some functions (i.e. : all the "Campaign" instances created by the factory)
    to prevent someone from directly call the "participate" function in this contract */
    mapping(address => bool) allowed;   
    // // stores the timestamp of the last time a user claims his rewards.
    // mapping(address => uint256) public lastClaim;
    // // stores the number of times a user has claimed his rewards. Acts as a nonce to prevent replay attacks.
    // mapping(address => uint) public nbClaim;

    mapping(address => mapping(uint => uint256)) public participations;
    mapping(uint => uint256) public totalParticipations;
    mapping(address => uint[]) public keys;

    uint256 public weeklySupply;

    uint tauxBBST = 125;
    uint tauxBNB = 240;
    uint tauxBUSD = 1;

    uint delayClaim = 300;

    constructor () {
        owner = msg.sender;
        rewardStartTimestamp = block.timestamp;
        active = true;
        totalParticipations[0] = 0;
        weeklySupply = 2500*10**18;
    }


    ////****modifiers****////

    modifier onlyAllowed() {
        require(allowed[msg.sender] == true, "You are not allowed to call this function");
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "You are not the Factory");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the Owner");
        _;
    }

    modifier onlyWhenActive() {
        require(active == true, "Rewards are not active at the moment");
        _;
    }

    ////**** Setters ****////

    function setActive(bool state) onlyOwner() external {
        active = state;
    }

    function setRewardTimestamp(uint256 time) onlyOwner() external {
        rewardStartTimestamp = time;
    }

    function addToAllowed(address newAddress) onlyFactory() public {
        allowed[newAddress] = true;
    }

    function setFactory(address factoryAddress) onlyOwner() public {
        factory = factoryAddress;
    }

    function setBalanceWeek(uint256 newBalance) external onlyOwner() {
        weeklySupply = newBalance;
    }

    function setTauxBBST(uint newTaux) external onlyOwner() {
        tauxBBST = newTaux;
    }

    function setTauxBUSD(uint newTaux) external onlyOwner() {
        tauxBUSD = newTaux;
    }

    function setTauxBNB(uint newTaux) external onlyOwner() {
        tauxBNB = newTaux;
    }

    //**** Functions ****/

    /***
    * Function called from a "Campaign" instance when a user makes a donation.
    * @param address sender : the user that made the donation, passed as argument.
    */
    function participate(address sender, uint256 amount, address token) onlyAllowed() public returns(bool) {

        uint256 amount_ = amount;
        uint week = (block.timestamp - rewardStartTimestamp) / delayClaim;

        if (token == address(0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee)) {
            amount_ = amount_ * tauxBUSD;
        } else if (token == address(0x0000000000000000000000000000000000000000)) {
            amount_ = amount_ * tauxBNB;
        } else if (token == address(0xa6F6F46384FD07f82A7756C48fFf7f0193108688)) {
            amount_ = (amount_ * tauxBBST) / 100;
        } else {
            revert("Wrong token address provided.");
        }
        
        if(participations[sender][week] == 0 || keys[sender].length == 0) {
            keys[sender].push(week);
        }

        participations[sender][week] += amount_;
        totalParticipations[week] += amount_;
        
        amount_ = 0;

        emit Participate(sender, block.timestamp, amount, token);
        return true;
    }


    function percent(uint256 numerator, uint256 denominator, uint precision) public pure returns(uint256 quotient) {
        // caution, check safe-to-multiply here
        uint256 _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint256 _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }


    function getClaim(address claimer) public view returns(uint256) {
        uint256 toClaim = 0;

        for (uint i = 0; i < keys[claimer].length; i++) {
            uint week = keys[claimer][i];
            uint256 ratio = percent(participations[msg.sender][week], totalParticipations[week], 7);
            uint256 gains = ratio > 3*10**5 ? percent(3*10**5 * weeklySupply,1*10**7,0) : percent(ratio * weeklySupply,1*10**7,0);
            toClaim += gains;
        }

        return toClaim;
    }


    /***
    * Function called when a user wants to claim its tokens.
    */
    function claimTokens() onlyWhenActive() external {

        require(((block.timestamp - rewardStartTimestamp) / delayClaim) > 0, "You cannot retrieve your tokens yet!");

        uint256 toClaim = 0;
        address bbst = address(0xa6F6F46384FD07f82A7756C48fFf7f0193108688);

        uint currentWeek = ((block.timestamp - rewardStartTimestamp) / delayClaim);
        uint elemCurrentWeek = 0;

        for (uint i = 0; i < keys[msg.sender].length; i++) {
            if (keys[msg.sender][i] == currentWeek) {
                elemCurrentWeek = keys[msg.sender][i];
            } else {
                uint week = keys[msg.sender][i];
                uint256 ratio = percent(participations[msg.sender][week], totalParticipations[week], 7);
                uint256 gains = ratio > 3*10**5 ? percent(3*10**5 * weeklySupply,1*10**7,0) : percent(ratio * weeklySupply,1*10**7,0);
                toClaim += gains;
            }
        }

        if (elemCurrentWeek == 0) {
            delete keys[msg.sender];
        } else {
            delete keys[msg.sender];
            keys[msg.sender].push(elemCurrentWeek);
        }

        IERC20(bbst).transfer(msg.sender, toClaim);

        emit Claimed(msg.sender, toClaim, block.timestamp);
    }


    // returns the amount of BBST on this contract
    function getBalance() onlyOwner() public view returns(uint256) {
        return IERC20(0xa6F6F46384FD07f82A7756C48fFf7f0193108688).balanceOf(address(this));
    }

    function getCurrrentWeek() public view returns(uint) {
        return (block.timestamp - rewardStartTimestamp) / delayClaim;
    }
}