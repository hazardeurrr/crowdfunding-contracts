const Campain = artifacts.require("Campain");

module.exports = function (deployer) {
  deployer.deploy(Campain, '0x57e2bf0b604c91b99e66e8cabf03a5d5a1e98385', 1, 1, 1618776000, 1618778000, true, 2, [1, 2]);
};
