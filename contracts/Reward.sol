
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Reward is Context {

    address owner;
    uint256 public rewardStartTimestamp;

    event Participation(address indexed user, uint timestamp, uint256 amount, address token);


    mapping(address => uint256) public rates;
    mapping(address => bool) public allowed;
    address factory;

    constructor () {
              rewardStartTimestamp = 1646393429;

        owner = msg.sender;
        rates[0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b] = 4000;
        rates[0x0000000000000000000000000000000000000000] = 1;
        rates[0x67c0fd5c30C39d80A7Af17409eD8074734eDAE55] = 2000;
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



    ////****functions****////

    function addToAllowed(address newAddress) onlyFactory() public {
        allowed[newAddress] = true;
    }

    function setFactory(address factoryAddress) onlyOwner() public{
        factory = factoryAddress;
    }

    function setRewardTimestamp(uint256 time) external returns(bool) {
        rewardStartTimestamp = time;
        return true;
    }

    function participate(address sender, uint256 amount, address token) onlyAllowed() public returns(bool) {
        emit Participation(sender, block.timestamp, amount, token);

        return true;
    }
}