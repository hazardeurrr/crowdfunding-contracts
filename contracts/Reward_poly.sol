
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Reward is Context {

    address owner;
    address admin;
    address factory;
    uint256 public rewardStartTimestamp;

    bool active;

    event Participate(address indexed user, uint timestamp, uint256 amount, address token);
    event Claimed(address claimer, uint256 amount, uint256 timestamp);

    mapping(address => bool) allowed;
    mapping(address => uint256) public lastClaim;
    mapping(address => uint) public nbClaim;

    constructor (address _admin) {
        owner = msg.sender;
        rewardStartTimestamp = block.timestamp;
        admin = _admin;
        active = true;
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
        require(msg.sender == owner, "You are not the Factory");
        _;
    }

    modifier onlyWhenActive() {
        require(active == true, "Rewards are not active at the moment");
        _;
    }

    ////****functions****////

    // to change the owner of the contract
    function changeOwner(address newOwner) public onlyOwner() {
        owner = newOwner;
    } 


    function setActive(bool state) onlyOwner() external {
        active = state;
    }

    function setRewardTimestamp(uint256 time) onlyOwner() external {
        rewardStartTimestamp = time;
    }

    function updateAdmin(address newAdmin) onlyOwner() external {
        admin = newAdmin;
    }

    function addToAllowed(address newAddress) onlyFactory() public {
        allowed[newAddress] = true;
    }

    function setFactory(address factoryAddress) onlyOwner() public{
        factory = factoryAddress;
    }

    function participate(address sender, uint256 amount, address token) onlyAllowed() public returns(bool) {
        emit Participate(sender, block.timestamp, amount, token);

        return true;
    }

    function getBalance() onlyOwner() public view returns(uint256) {
        return IERC20(0x24600539D8Fa2D29C58366512d08EE082A6c0cB3).balanceOf(address(this));
    }
}