
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

    function claimTokens(uint amount, bytes calldata signature) onlyWhenActive() external {

        address recipient = msg.sender;
        bytes32 message = prefixed(keccak256(abi.encodePacked(recipient, amount, nbClaim[recipient])));

        require(recoverSigner(message, signature) == admin, "CLAIM DENIED : WRONG SIGNATURE");

        // BBST token address
        lastClaim[recipient] = block.number;
        nbClaim[recipient] += 1;
        
        IERC20(0x67c0fd5c30C39d80A7Af17409eD8074734eDAE55).transfer(recipient, amount);

        emit Claimed(recipient, amount, block.timestamp);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {

        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
    
        (v, r, s) = splitSignature(sig);
    
        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);
    
        bytes32 r;
        bytes32 s;
        uint8 v;
    
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    
        return (v, r, s);
    }

    function getLastClaim(address claimer) public view returns(uint256) {
        return lastClaim[claimer];
    }

    function getBalance() onlyOwner() public view returns(uint256) {
        return IERC20(0x67c0fd5c30C39d80A7Af17409eD8074734eDAE55).balanceOf(address(this));
    }
}