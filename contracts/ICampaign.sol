pragma solidity ^0.8.0;

interface ICampaign {
    
    event CampaignCreation(address campaignAddress, address creator, uint timestamp, uint goal, address token);
    event Participation(address from, uint campaign_id, uint amount, uint totalBalance);
    event CreatorPaid(address creator, uint total_amount);
    event Refund(address from, address to, uint refund_amount);
    event CampaignCreated(address creator, uint timestamp, uint goal, address token);
    event Refund(address from, uint refundAmount);
    function initialize(address payable creator_,
        uint campaign_id_,
        uint goal_,
        uint startTimestamp_,
        uint endTimestamp_,
        bool partialGoal_,
        address token_,
        uint nbTiers_,
        uint[] memory tiers_) external;
    function payCreator() external;
    receive() external payable;
}