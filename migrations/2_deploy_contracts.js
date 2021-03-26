const QLCCoin = artifacts.require("QLCToken");
const QGasCoin = artifacts.require("QGasToken");

const { deployProxy } = require('@openzeppelin/truffle-upgrades');

module.exports = async function (deployer) {
   await deployProxy(QLCCoin, ['QLCToken', 'QLC'], { deployer });
   await deployProxy(QGasCoin, ['QGasToken', 'QGas', 0], { deployer });
};
