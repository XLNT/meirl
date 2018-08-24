pragma solidity ^0.4.24;

import "zos-lib/contracts/upgradeability/AdminUpgradeabilityProxy.sol";


contract AdminUpgradeabilityProxyMock is AdminUpgradeabilityProxy {
  constructor (address _implementation)
    AdminUpgradeabilityProxy(_implementation)
    public
  {
  }
}
