pragma solidity ^0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/QLCToken.sol";

contract TestQLCToken {
  function testInitialOwnerBalanceUsingDeployedContract() public {
    QLCToken meta = QLCToken(DeployedAddresses.QLCToken());
    uint expected = 0;
    Assert.equal(meta.balanceOf(tx.origin), expected, "Owner should have 0 QLCToken initially");
  }
}