pragma solidity ^0.8.0;

interface ICampaign {
    
    event CampaignCreation(address campaignAddress, address creator, uint timestamp, address token);
    event Participation(address indexed user, uint amount, address campaign, uint indexTier);
    event CreatorPaid(address creator, uint total_amount);
    function initialize(address payable creator_,
        uint campaign_id_,
        address token_,
        address bbstAddr_,
        address feesAddr_,
        uint256[] memory amounts_,
        int256[] memory stock_,
        uint baseFeeRate_,
        uint bbstFeeRate_,
        string[] memory tokenURIs_,
        string memory contractURI_
        ) external;
    function payCreator() external;
    function payCreatorERC20() external;
    receive() external payable;
}