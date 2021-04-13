pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Contract CrowdFund
/// @author hderoche
/// @notice Single contract for one crowdFund
/// @dev Instance of a CrowdFund
contract CrowdFund is Ownable {
    string public name;
    mapping(address => uint256) public balance;
    mapping(address => uint8) public _tiers;

    // goal
    uint256 public goal;

    // Tiers
    uint8 nbTiers;
    uint256[] public tiersStage;
    // Start of the campain
    uint256 public timestamp;

    constructor (uint256 timestamp_, uint256 goal_, uint256[] memory tiersStage_, uint8 nbTiers_) {
        timestamp = timestamp_;
        goal = goal_;
        nbTiers = nbTiers_;
        tiersStage = tiersStage_;
    }

    /// @notice Event that keeps track of each participation
    /// @dev Sending an event for each participation
    event Participation(address from, uint256 amount, uint8 tiers);

    modifier nonAddressZero(address add) {
        require(add != address(0), 'Address 0 cannot receive/send funds');
        _;
    }

    receive() payable external {
        participate();
        // set the tier of the participation
        emit Participation(msg.sender, msg.value, 1);
    }


    /// @notice Function called when someone sends money to this crowdfund
    /// @dev After verifying balance and the address, sends the value to the contract, keep a trace of the invest and sets the tier for this address
    function participate() public payable nonAddressZero(msg.sender) {
        require(msg.value > 0, 'You cannot send a negative or null amount');
        balance[msg.sender] += msg.value;
        // set the tier of the participation
        setTiers(msg.sender, msg.value);
    }

    /// @notice This function sets the tier for the sender based on how much he contributed
    /// @dev using a inverted for loop to set the correct tier
    /// @param from address of the sender
    /// @param amount value that the sender contributed to the funding
    function setTiers(address from, uint256 amount) internal {
        for (uint i = nbTiers; i > 0; i--) {
            if (amount > tiersStage[i]) {
                _tiers[from] = i;
            }
        }
    }

    /// @notice Update the tier of the contributor
    /// @dev Checks for the balance and the total amount spent to update the tier accordingly
    /// @param from address of the sender
    function updateTiers(address from) internal {
        require(_tiers[from] > 0, 'you have not contributed to this project yet');
        setTiers(from, balance[from]);
    }
}