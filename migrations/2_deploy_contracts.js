const QLCCoin = artifacts.require("QLCToken");

const { deployProxy } = require('@openzeppelin/truffle-upgrades');

module.exports = async function (deployer) {
   await deployProxy(QLCCoin, ['QLCToken', 'qlc'], { deployer });
};