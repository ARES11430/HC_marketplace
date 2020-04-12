const HCTToken = artifacts.require("HCTToken");

module.exports = function(deployer) {
  deployer.deploy(HCTToken);
};