pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "./BlockBoosted.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Cashback is Context {

    using SafeMath for uint;

    mapping(address => mapping(uint => uint256)) public participations;
    mapping(uint => uint256) public totalWeek;
    mapping(uint => uint256) public totalParticipations;

    mapping(address => uint[]) public keys;

    uint tauxBBST = 1;
    uint tauxETH = 1;
    uint tauxUSDC = 1;

    uint256 rewardStartTimestamp;

    address owner;

    constructor () {
        totalWeek[0] = 30000;
        owner = msg.sender;
        totalParticipations[0] = 0;
        rewardStartTimestamp = block.timestamp;
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "You are not the Owner");
        _;
    }

    function setBalanceWeek(uint256 newBalance, uint week) external onlyOwner() returns(bool) {
        totalWeek[week] = newBalance;
        return true;
    }

    function setTauxBBST(uint newTaux) external onlyOwner() returns(bool) {
        tauxBBST = newTaux;
        return true;
    }

    function setTauxUSDC(uint newTaux) external onlyOwner() returns(bool) {
        tauxUSDC = newTaux;
        return true;
    }

    function setTauxETH(uint newTaux) external onlyOwner() returns(bool) {
        tauxETH = newTaux;
        return true;
    }


    function participate(uint256 amount, address token) public returns(bool) {

        require(amount > 0, "The amount must be positive!");

        uint256 amount_ = amount;
        uint week = (block.timestamp - rewardStartTimestamp) / 604800;

        if (token == address(0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b)) {
            amount_ = amount_ * tauxUSDC;
        } else if (token == address(0x0000000000000000000000000000000000000000)) {
            amount_ = amount_ * tauxETH;
        } else if (token == address(0x67c0fd5c30C39d80A7Af17409eD8074734eDAE55)) {
            amount_ = amount_ * tauxBBST;
        } else {
            revert("Wrong token address provided.");
        }
        
        participations[msg.sender][week] += amount_;
        totalParticipations[week] += amount_;
        keys[msg.sender].push(week);
        amount_ = 0;

        return true;
    }


    function getClaim(address claimer) public view returns(uint256) {
        uint256 toClaim = 0;

        for (uint i = 0; i < keys[claimer].length; i++) {
            uint week = keys[claimer][i];
            toClaim += (participations[msg.sender][week] / totalWeek[week]) * totalParticipations[week];
        }

        return toClaim;
    }


    function claimTokens(address payable claimer) payable public returns(bool) {
        uint256 toClaim = 0;
        address bbst = address(0x67c0fd5c30C39d80A7Af17409eD8074734eDAE55);

        for (uint i = 0; i < keys[claimer].length; i++) {
            uint week = keys[claimer][i];
            toClaim += (participations[msg.sender][week] / totalWeek[week]) * totalParticipations[week];
        }

        IERC20(bbst).transfer(claimer, toClaim);
        return true;
    }


}