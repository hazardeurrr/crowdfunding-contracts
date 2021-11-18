const CampainFactory = artifacts.require("CampaignFactory");

module.exports = function (deployer) {
  deployer.deploy(CampainFactory);
};
