pragma solidity ^0.4.24;

import "../util/Types.sol";
import "../util/KeyRoles.sol";

contract KeyManagerStorage {
  event PendingPurposeAdded(bytes32 indexed keyId, Types.Purpose indexed purpose, uint256 timeout);
  event PendingPurposeRemoved(bytes32 indexed keyId, Types.Purpose indexed purpose);
  event PurposeAdded(bytes32 indexed keyId, Types.Purpose indexed purpose);
  event PurposeRemoved(bytes32 indexed keyId, Types.Purpose indexed purpose);

  mapping (uint256 => KeyRoles.Role) internal roles;

  uint256 public numManagers;

  /**
   * @dev array of keys for enumeration
   */
  Types.Key[] internal keys;

  /**
   * @dev maps from (keyId) => index in `keys`
   */
  mapping(bytes32 => uint256) internal keyIndex;

  uint256 internal MAX_PURPOSES;

  mapping(bytes32 => uint256) internal pendingManagerTimeouts;
}
