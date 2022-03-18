
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Reward is Context {

    address owner;
    uint256 public rewardStartTimestamp;

    event Participation(address indexed user, uint timestamp, uint256 amount, address token);


    mapping(address => uint256) public rates;
    mapping(address => bool) public allowed;
    address factory;

    constructor (address _admin) {
        owner = msg.sender;
        //rewardStartTimestamp = block.timestamp;
        rewardStartTimestamp = 1646393429;
        admin = _admin;
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

    modifier onlyAdmin() {
        require(admin == _msgSender(), "You are not the Admin");
    }

    ////****functions****////

    function setRewardTimestamp(uint256 time) external returns(bool) {
        rewardStartTimestamp = time;
        return true;
    }

    function updateAdmin(address newAdmin) onlyAdmin() external {
        admin = newAdmin;
    }

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

    function claimTokens(address recipient, uint amount, bytes calldata signature) external {
        bytes32 message = prefixed(keccak256(abi.encodePacked(recipient, amount)));

        require(recoverSigner(message, signature) == admin , 'CLAIM DENIED : WRONG SIGNATURE');

        token.transfer(recipient, amount);
        lastClaim[recipient] = block.timestamp;

        emit Claimed(recipient, amount, block.timestamp);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash));
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

    function getCurrentWeek() public view returns(uint) {
        return (block.timestamp - rewardStartTimestamp) / 604800;
    }

    function getStartTimestamp() public view returns(uint) {
        return rewardStartTimestamp;
    }
}