pragma solidity ^0.4.24;

import "zos-lib/contracts/migrations/Migratable.sol";
import "openzeppelin-solidity/contracts/ECRecovery.sol";

import "../../util/Types.sol";
import "../../interfaces/IIdentity.sol";
import "../../interfaces/IActionValidator.sol";

import "./Executor01.sol";
import "./KeyManager01.sol";

/**
 * @title IdentityImplementation01
 * @dev Implements identity by managing keys, executing functions, and validating signatures.
 */
contract IdentityImplementation01 is IIdentity, IActionValidator, Migratable, KeyManager01, Executor01 {
  using ECRecovery for bytes32;

  /**
   * @dev Initialize Identity by initializing KeyManager
   */
  function initialize(bytes32 _keyId, Types.KeyType _keyType, bytes8 _purposes)
    isInitializer("IdentityImplementation", "01")
    public
  {
    KeyManager01.initialize(_keyId, _keyType, _purposes);
  }

  /**
   * @dev An action is valid iff the _signature of the _action is from an key with the ACTION purpose
   */
  function isValidAction(bytes32 _action, bytes _signature)
    view
    external
    returns (bool)
  {
    address signer = _action.toEthSignedMessageHash().recover(_signature);
    bytes32 keyId = KeyUtils.idForAddress(signer);
    return keyHasPurpose(keyId, PURPOSE_ACTION);
  }
}
