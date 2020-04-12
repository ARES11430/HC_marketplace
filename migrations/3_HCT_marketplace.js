const HCTMarketplace = artifacts.require("HCTMarketplace");

module.exports = function(deployer) {
  deployer.deploy(HCTMarketplace);
};