
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Reward is Context {

    address owner;
    address admin;  // public key, used to verify signature
    address factory;    // address of the factory contract
    uint256 public rewardStartTimestamp;    // timestamp of the beginning of the reward system

    bool active;    // is the reward system active or not

    // event sent when a user donate to a campaign
    event Participate(address indexed user, uint timestamp, uint256 amount, address token);
    // event sent when a user claims his rewards
    event Claimed(address claimer, uint256 amount, uint256 timestamp);

    /*** addresses that are allowed to call some functions (i.e. : all the "Campaign" instances created by the factory)
    to prevent someone from directly call the "participate" function in this contract without */
    mapping(address => bool) allowed;   
    // stores the timestamp of the last time a user claims his rewards.
    mapping(address => uint256) public lastClaim;
    // stores the number of times a user has claimed his rewards. Acts as a nonce to prevent replay attacks.
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

    ////**** Setters ****////

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

    //**** Functions ****/

    /***
    * Function called from a "Campaign" instance when a user makes a donation.
    * @param address sender : the user that made the donation, passed as argument.
    */
    function participate(address sender, uint256 amount, address token) onlyAllowed() public returns(bool) {
        emit Participate(sender, block.timestamp, amount, token);

        return true;
    }


    /***
    * Function called when a user wants to claim its tokens.
    * @param amount : the amount of BBST to be claimed (in wei)
    * @param signature : the signature returned by our backend to approve this transaction. Returns an encoded message
    * in format receiverAddress|amountToBeClaimed|nonce with a secret private key
    */
    function claimTokens(uint amount, bytes calldata signature) onlyWhenActive() external {

        address recipient = msg.sender;
        // rebuild the message receiver|amount|nonce and encode it
        bytes32 message = prefixed(keccak256(abi.encodePacked(recipient, amount, nbClaim[recipient])));
        // check if signature is correct
        require(recoverSigner(message, signature) == admin, "CLAIM DENIED : WRONG SIGNATURE");

        lastClaim[recipient] = block.timestamp;
        nbClaim[recipient] += 1;
        
        IERC20(0x67c0fd5c30C39d80A7Af17409eD8074734eDAE55).transfer(recipient, amount);

        emit Claimed(recipient, amount, block.timestamp);
    }


    /***
    * Conventional semantic for signed messages using keccak256
    */ 
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }


    /***
    * Using the message and the signature separately we recover the admin address
    * @param message : the message from the user
    * @param sig : the signature used to sign the message
    */ 
    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
    
        (v, r, s) = splitSignature(sig);
    
        return ecrecover(message, v, r, s);
    }


    /***
    * Split the signature in 3 parts of 32 bytes in order to recover it using the message
    * @param sig : the signature used to sign the message
    */ 
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

    // returns the amount of BBST on this contract
    function getBalance() onlyOwner() public view returns(uint256) {
        return IERC20(0x67c0fd5c30C39d80A7Af17409eD8074734eDAE55).balanceOf(address(this));
    }
}