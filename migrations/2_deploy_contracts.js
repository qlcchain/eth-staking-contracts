const QLCToken = artifacts.require("QLCToken");

module.exports = function (deployer) {
  deployer.deploy(QLCToken);
};
