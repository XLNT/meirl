pragma solidity ^0.4.24;

import "zos-lib/contracts/upgradeability/AdminUpgradeabilityProxy.sol";


contract CustomAdminUpgradeabilityProxy is AdminUpgradeabilityProxy {
  bytes32 private constant IMPLEMENTATION_SLOT = keccak256("org.zeppelinos.proxy.implementation.custom");
}
