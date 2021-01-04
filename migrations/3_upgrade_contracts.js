const QLCToken = artifacts.require('QLCToken');
const QLCTokenV2 = artifacts.require('QLCTokenV2');

const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

module.exports = async function (deployer) {
  const  g = await QLCToken.deployed();
  await upgradeProxy(g.address, QLCTokenV2, { deployer });
}