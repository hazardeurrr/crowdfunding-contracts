pragma solidity ^0.8.0;

interface ICampaign {
    
    event CampaignCreation(address campaignAddress, address creator, uint timestamp, uint goal, address token);
    event Participation(address indexed user, uint amount, address campaign, uint indexTier);
    event CreatorPaid(address creator, uint total_amount);
    event CampaignCreated(address creator, uint timestamp, uint goal, address token);
    function initialize(address payable creator_,
        uint campaign_id_,
        uint goal_,
        uint startTimestamp_,
        uint endTimestamp_,
        address token_,
        uint256[] memory amounts_,
        int256[] memory stock_
        ) external;
    function payCreator() external;
    function payCreatorERC20() external;
    receive() external payable;
}