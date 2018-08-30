pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "zos-lib/contracts/migrations/Migratable.sol";

import "../../util/Types.sol";
import "../../util/KeyUtils.sol";
import "../../util/KeyRoles.sol";

import "../../interfaces/IKeyManager.sol";

/**
 * @title KeyManagerStorage01
 * @dev Manages key storage.
 */
contract KeyManagerStorage01 {
  event PurposeAdded(bytes32 indexed keyId, Types.Purpose indexed purpose);
  event PurposeRemoved(bytes32 indexed keyId, Types.Purpose indexed purpose);

  mapping (uint256 => KeyRoles.Role) internal roles;

  /**
   * @dev array of keys for enumeration
   */
  Types.Key[] internal keys;

  /**
   * @dev maps from (keyId) => index in `keys`
   */
  mapping(bytes32 => uint256) internal keyIndex;

  uint256 internal constant MAX_PURPOSES = 256; // why not
}


/**
 * @title KeyManager01
 * @dev Implements key management logic, storage, and enumeration.
 */
contract KeyManager01 is Migratable, IKeyManager, IKeyManagerEnumerable, KeyManagerStorage01 {
  using KeyRoles for KeyRoles.Role;
  using SafeMath for uint256;

  // this is overriden by GnosisSafe in Identity
  modifier authorized()
  {
    _;
  }

  /**
   * @dev initializes the contract, adding a single key with specific purposes
   * @param _keyId the id of the key
   * @param _keyType the type of the key
   * @param _purposes the purposes of the key
   */
  function initialize(
    bytes32 _keyId,
    Types.KeyType _keyType,
    Types.Purpose[] memory _purposes
  )
    public
    isInitializer("KeyManager", "0")
  {
    _addKey(_keyId, _keyType, _purposes);
  }

  /**
   * @dev return information about a key, namely its keyType
   * @param _keyId the id of the key
   */
  function getKey(
    bytes32 _keyId
  )
    external
    view
    returns (
      bytes32 keyId,
      Types.KeyType keyType
    )
  {
    Types.Key storage key = _getKeyById(_keyId);

    return (
      key.id,
      key.keyType
    );
  }

  /**
   * @dev query the permission of a key for an identity
   * @param _keyId the id of the key
   * @param _purpose the purpose in question
   */
  function keyHasPurpose(
    bytes32 _keyId,
    Types.Purpose _purpose
  )
    public
    view
    returns (
      bool
    )
  {
    return _hasPurpose(_keyId, _purpose);
  }

  function totalKeys()
    external
    view
    returns (
      uint256 keyCount
    )
  {
    return keys.length;
  }

  function keyByIndex(
    uint256 _index
  )
    external
    view
    returns (
      bytes32 keyId
    )
  {
    return keys[_index].id;
  }

  // WRITE

  function addKey(
    bytes32 _keyId,
    Types.KeyType _keyType,
    Types.Purpose[] _purposes
  )
    public
    authorized
    returns (
      bool success
    )
  {
    return _addKey(_keyId, _keyType, _purposes);
  }

  function removeKey(
    bytes32 _keyId
  )
    public
    authorized
    returns (
      bool success
    )
  {
    return _removeKey(_keyId);
  }

  // INTERNAL

  function _hasPurpose(bytes32 _keyId, Types.Purpose _purpose)
    internal
    view
    returns (bool)
  {
    return roles[uint256(_purpose)].has(_keyId);
  }

  /**
   * @dev add a role to an address
   * @param _keyId address
   * @param _purpose the purpose
   */
  function _addPurpose(bytes32 _keyId, Types.Purpose _purpose)
    internal
  {
    roles[uint256(_purpose)].add(_keyId);
    emit PurposeAdded(_keyId, _purpose);
  }

  /**
   * @dev remove a role from an address
   * @param _keyId address
   * @param _purpose the purpose
   */
  function _removePurpose(bytes32 _keyId, Types.Purpose _purpose)
    internal
  {
    roles[uint256(_purpose)].remove(_keyId);
    emit PurposeRemoved(_keyId, _purpose);
  }

  function _addPurposes(bytes32 _keyId, Types.Purpose[] _purposes)
    internal
  {
    for (uint256 i = 0; i < _purposes.length; i++) {
      _addPurpose(_keyId, _purposes[i]);
    }
  }

  function _removeAllPurposes(bytes32 _keyId)
    internal
  {
    for (uint256 i = 0; i < MAX_PURPOSES; i++) {
      _removePurpose(_keyId, Types.Purpose(i));
    }
  }

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
    Types.Purpose[] memory _purposes
  )
    internal
    returns (bool)
  {
    // update this.keys
    Types.Key memory key = Types.Key({
      id: _keyId,
      keyType: _keyType
    });
    keys.push(key);

    // update keyIndex
    keyIndex[_keyId] = keys.length - 1;

    // update purposes
    _addPurposes(_keyId, _purposes);

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

    _removeAllPurposes(_keyId);

    return true;
  }
}
