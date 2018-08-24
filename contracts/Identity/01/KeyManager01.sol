pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "zos-lib/contracts/migrations/Migratable.sol";

import "../../util/Flags.sol";
import "../../util/Types.sol";
import "../../util/SelfAuthorized.sol";
import "../../util/KeyUtils.sol";

import "../../interfaces/IKeyManager.sol";

/**
 * @title KeyManagerStorage01
 * @dev Manages key storage.
 */
contract KeyManagerStorage01 {

  // logical limit of 64 different purposes because bytes8 has 64 bits
  uint8 constant public MAX_PERMISSIONS = 64;

  bytes8 constant public PURPOSE_GOD        = bytes8(~0); // [...] 11111111 11111111 11111111 11111111
  // ^ the reason for the god purpose is to make sure that, no matter how the implementation of
  // an identity contract changes, the initial key is ALWAYS going to have the permission to do anything it
  // wants to the identity. Intelligent clients will then immediately create a multiSend transaction from
  // the new identity adding a newly generated key and revoking the initial god address

  bytes8 constant public PURPOSE_MANAGEMENT = bytes8(1);  // [...] 00000000 00000000 00000000 00000001
  bytes8 constant public PURPOSE_ACTION     = bytes8(2);  // [...] 00000000 00000000 00000000 00000010
  bytes8 constant public PURPOSE_CLAIM      = bytes8(4);  // [...] 00000000 00000000 00000000 00000100
  bytes8 constant public PURPOSE_ENCRYPTION = bytes8(8);  // [...] 00000000 00000000 00000000 00001000
  // ...

  /**
   * @dev maps from (keyId, purpose) => hasPurpose
   */
  mapping(bytes32 => mapping(bytes8 => bool)) internal hasPurpose;

  /**
   * @dev array of keys for enumeration
   */
  Types.Key[] internal keys;

  /**
   * @dev maps from (keyId) => index in `keys`
   */
  mapping(bytes32 => uint256) internal keyIndex;
}


/**
 * @title KeyManager01
 * @dev Implements key management logic, storage, and enumeration.
 */
contract KeyManager01 is Migratable, IKeyManager, IKeyManagerEnumerable, KeyManagerStorage01, SelfAuthorized {
  using SafeMath for uint256;
  using Flags for bytes8;

  function initialize(
    bytes32 _keyId,
    Types.KeyType _keyType,
    bytes8 _purposes
  )
    public
    isInitializer("KeyManager", "01")
  {
    _addKey(_keyId, _keyType, _purposes);
  }

  function getKey(
    bytes32 _keyId
  )
    public
    view
    returns(
      bytes32 keyId,
      uint256 keyType,
      bytes8 purposes
    )
  {
    Types.Key storage key = _getKeyById(_keyId);

    return (
      key.id,
      uint256(key.keyType),
      key.purposes
    );
  }

  function keyHasPurpose(
    bytes32 _keyId,
    bytes8 _purpose
  )
    public
    view
    returns(bool)
  {
    Types.Key storage key = _getKeyById(_keyId);
    return key.purposes.hasFlag(_purpose);
  }

  // WRITE

  function addKey(
    bytes32 _keyId,
    Types.KeyType _keyType,
    bytes8 _purposes
  )
    public
    authorized
    returns (
      bool success
    )
  {

    _addKey(_keyId, _keyType, _purposes);
    return true;
  }

  function removeKey(
    bytes32 _keyId
  )
    public
    authorized
    returns (bool)
  {
    _removeKey(_keyId);
    return true;
  }

  // INTERNAL

  function _getKeyById(
    bytes32 _keyId
  )
    internal
    view
    returns (Types.Key storage)
  {
    return keys[keyIndex[_keyId]];
  }

  function _addKey(
    bytes32 _keyId,
    Types.KeyType _keyType,
    bytes8 _purposes
  )
    internal
    returns (bool)
  {

    // update this.keys
    Types.Key memory key = Types.Key({
      id: _keyId,
      keyType: _keyType,
      purposes: _purposes
    });
    keys.push(key);

    // update this.keyIndex
    keyIndex[_keyId] = keys.length - 1;

    // update this.hasPurpose
    _addKeyPurposes(_keyId, _purposes);

    return true;
  }

  function _removeKey(
    bytes32 _keyId
  )
    internal
    returns (bool)
  {

    // To prevent a gap in the array, we store the last token in the index of the token to delete,
    // and then delete the last slot.
    uint256 currIndex = keyIndex[_keyId];
    // ^ current index of the key to delete
    uint256 lastKeyIndex = keys.length.sub(1);
    // ^ the index of the last key
    Types.Key memory lastKey = keys[lastKeyIndex];
    // ^ the lastKey's information, copied into memory

    keys[currIndex] = lastKey;
    // ^ replace the key storage at currIndex with the lastKey's values
    keys.length--;
    // ^ manually deallocate the last key's storage, nuking it from storage

    // Note that this will handle single-element arrays. In that case, both index and lastKeyIndex are going to
    // be zero. Then we can make sure that we will remove _keyId from the ownedTokens list since we are first swapping
    // the lastKey to the first position, and then dropping the element placed in the last position of the list

    keyIndex[_keyId] = 0;
    // ^ reset keyIndex
    keyIndex[lastKey.id] = currIndex;
    // ^ update keyIndex for the last key to be currIndex

    _removeKeyPurposes(_keyId);

    return true;
  }

  function _addKeyPurposes(
    bytes32 _keyId,
    bytes8 _purposes
  )
    internal
    returns (bool)
  {
    for (uint8 i = 0; i < MAX_PERMISSIONS; i++) {
      bytes8 flag = bytes8(1) << i;
      hasPurpose[_keyId][flag] = _purposes.hasFlag(flag);
    }
    return true;
  }

  function _removeKeyPurposes(
    bytes32 _keyId
  )
    internal
    returns (bool)
  {
    for (uint8 i = 0; i < MAX_PERMISSIONS; i++) {
      bytes8 flag = bytes8(1) << i;
      delete hasPurpose[_keyId][flag];
    }

    return true;
  }
}
