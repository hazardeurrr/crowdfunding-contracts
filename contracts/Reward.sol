pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Reward is Context {

    using SafeMath for uint;

    mapping(address => mapping(uint => uint256)) public participations;
    mapping(uint => uint256) public totalWeek;
    mapping(uint => uint256) public totalParticipations;

    mapping(address => uint[]) public keys;

    uint tauxBBST = 1;
    uint tauxETH = 1;
    uint tauxUSDC = 1;

    // uint currWeek = 1;

    uint256 public rewardStartTimestamp;

    address owner;

    constructor () {
        totalWeek[0] = 30000*10**18;
        owner = msg.sender;
        totalParticipations[0] = 0;
        //rewardStartTimestamp = block.timestamp;
        rewardStartTimestamp = 1646393429;
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

    function setRewardTimestamp(uint256 time) external returns(bool) {
        rewardStartTimestamp = time;
        return true;
    }


    function participate(address sender, uint256 amount, address token) public returns(bool) {

        uint256 amount_ = amount;
        uint week = ((block.timestamp - rewardStartTimestamp) / 604800);

        if (token == address(0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b)) {
            amount_ = amount_ * tauxUSDC;
        } else if (token == address(0x0000000000000000000000000000000000000000)) {
            amount_ = amount_ * tauxETH;
        } else if (token == address(0x67c0fd5c30C39d80A7Af17409eD8074734eDAE55)) {
            amount_ = amount_ * tauxBBST;
        } else {
            revert("Wrong token address provided.");
        }
        
        if(participations[sender][week] == 0 || keys[sender].length == 0) {
            keys[sender].push(week);
        }

        participations[sender][week] += amount_;
        totalParticipations[week] += amount_;
        
        amount_ = 0;

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
            uint256 gains = ratio > 3*10**5 ? percent(3*10**5 * totalWeek[week],1*10**7,0) : percent(ratio * totalWeek[week],1*10**7,0);
            toClaim += gains;
        }

        return toClaim;
    }


    function claimTokens() payable public returns(bool) {
        require(((block.timestamp - rewardStartTimestamp) / 604800) > 0, "You cannot retrieve your tokens yet!");

        uint256 toClaim = 0;
        address bbst = address(0x67c0fd5c30C39d80A7Af17409eD8074734eDAE55);

        uint currentWeek = ((block.timestamp - rewardStartTimestamp) / 604800);
        uint elemCurrentWeek = 0;

        for (uint i = 0; i < keys[msg.sender].length; i++) {
            if (keys[msg.sender][i] == currentWeek) {
                elemCurrentWeek = keys[msg.sender][i];
            } else {
                uint week = keys[msg.sender][i];
                uint256 ratio = percent(participations[msg.sender][week], totalParticipations[week], 7);
                uint256 gains = ratio > 3*10**5 ? percent(3*10**5 * totalWeek[week],1*10**7,0) : percent(ratio * totalWeek[week],1*10**7,0);
                toClaim += gains;
            }
        }

        IERC20(bbst).transfer(msg.sender, toClaim);

        if (elemCurrentWeek == 0) {
            delete keys[msg.sender];
        } else {
            delete keys[msg.sender];
            keys[msg.sender].push(elemCurrentWeek);
        }

        return true;
    }

    function getKeys(address claimer) public view returns(uint256[] memory) {
        return keys[claimer];
    }

    function getParticipations(address claimer, uint week) public view returns(uint256) {
        return participations[claimer][week];
    }

    function getTotalWeek(uint week) public view returns(uint256) {
        return totalWeek[week];
    }

    function getTotalParticipations(uint week) public view returns(uint256) {
        return totalParticipations[week];
    }

    function getCurrrentWeek() public view returns(uint) {
        return ((block.timestamp - rewardStartTimestamp) / 604800);
    }


}