pragma solidity ^0.8.0;

import './CampaignInstance.sol';
// import './Proxy.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// Deploying 
// Deploy first the Campaign contract first and in the callback deploy the CampaignFactory and set the Campaign address in the constructor of the 
// CampaignFactory



contract CampaignFactory is Ownable {
    using SafeMath for uint;

    mapping(address => bool) public blacklist;
    struct CampaignSaved {
        Campaign campaignAddress;
        uint id;
    }
    mapping(address => CampaignSaved) public campaigns;
    mapping(address => uint) public creatorCampaignNumber;
    address[]  public allCrowdFund;
    address public masterCampaignAddress;
    uint256 public nbCampaign;
    IERC20 public token;
    
    // TOKEN ADDRESSES
    address usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address bbst = address(0);

    event CampaignCreated(address creator, uint nbCampaign, uint goal);

    modifier isWhitelisted() {
        require(blacklist[msg.sender] == false, 'You are not allowed to interract with the contract');
        _;
    }

    constructor(address masterCampaignAddress_) {
        nbCampaign = 0;
        masterCampaignAddress = masterCampaignAddress_;
    }

    function createCampaign(
        uint goal_, 
        uint startTimestamp_, 
        uint endTimestamp_, 
        bool partialGoal_,
        uint tokenChoice,
        uint nbTiers_,
        uint[] memory listTiers_
        ) payable external isWhitelisted() returns(bool) {
        require(msg.sender != address(0), 'address not valid');
        if (tokenChoice == 0) {
            token = IERC20(usdt);
            
        } else if (tokenChoice == 1) {
            token = IERC20(bbst);
            
        } else {
          // pay in ether
          token = IERC20(address(0));
        }
        Campaign newCampaign = Campaign(payable(createClone(masterCampaignAddress)));
        newCampaign.initialize(payable(msg.sender), nbCampaign, goal_, startTimestamp_, endTimestamp_, partialGoal_, token, nbTiers_, listTiers_);
        uint crCampaignNumber = creatorCampaignNumber[msg.sender];
        campaigns[msg.sender] = CampaignSaved(newCampaign, crCampaignNumber);
        nbCampaign += 1;
        emit CampaignCreated(msg.sender, nbCampaign, goal_);
        return true;
    }

    function addToBlacklist(address newAddress) public {
        blacklist[newAddress] = true;
    }
    
    function removeFromBlacklist(address addressToRemove) public {
        blacklist[addressToRemove] = false;
    }

    // function getCampaign(address creator) external view returns(Campaign _campaign) {
    //     return campaigns[creator];
    // }

    function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

}