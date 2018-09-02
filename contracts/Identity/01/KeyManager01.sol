pragma solidity ^0.4.24;

import "gnosis-safe/contracts/GnosisSafe.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ECRecovery.sol";
import "zos-lib/contracts/migrations/Migratable.sol";

import "../../put-this-in-openzeppelin/BouncerUtils.sol";

import "../../util/Types.sol";
import "../../util/KeyUtils.sol";
import "../../util/KeyRoles.sol";

import "../../interfaces/IKeyManager.sol";
import "../KeyManagerStorage.sol";
import "./NoOwnerInterface01.sol";

/**
 * @title KeyManager01
 * @dev Implements key management logic, storage, and enumeration on top of a GnosisSafe
 */
contract KeyManager01 is IKeyManager, Migratable, IKeyManagerEnumerable, KeyManagerStorage, NoOwnerInterface01, GnosisSafe {
  using KeyRoles for KeyRoles.Role;
  using ECRecovery for bytes32;
  using KeyUtils for address;
  using SafeMath for uint256;

  /**
   * @dev initializes the contract, adding a single key with specific purposes
   * @param _initialKey the initial owner address
   */
  function initialize(
    address _initialKey
  )
    public
    isInitializer("KeyManager", "0")
  {
    _addManager(_initialKey.keyId());
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
    external
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
    Types.Purpose _purpose,
    bytes _signature
  )
    external
    returns (
      bool success
    )
  {
    uint256 numSignatures = _numSignatures(_signature);

    // _someone_ has to have signed off on this addKey
    require(numSignatures >= 1, "NOT_ENOUGH_MANAGERS");
    // check that all signatures are valid and managers
    require(checkManagerSignatures(BouncerUtils.getMessageData(), _signature), "INVALID_SIGNATURES");

    if (_purpose == Types.Purpose.MANAGEMENT) {
      if (numSignatures >= _simpleManagerMajority()) {
        // we're adding a manager with a simple majority, immediately add
        return _addManager(_keyId);
      } else {
        // we're adding a manager with a minority
        // i.e. numSignatures >= 1 but < simpleManagerMajority
        // so set a timeout
        // solium-disable-next-line security/no-block-members
        pendingManagerTimeouts[_keyId] = block.timestamp + 2 days;
        emit PendingPurposeAdded(_keyId, _purpose, pendingManagerTimeouts[_keyId]);

        return true;
      }
    }

    return _addKey(_keyId, _keyType, _purpose);
  }

  function removeKey(
    bytes32 _keyId,
    Types.Purpose _purpose,
    bytes _signature
  )
    external
    returns (
      bool success
    )
  {
    uint256 numSignatures = _numSignatures(_signature);

    // _someone_ has to have signed off on this
    require(numSignatures >= 1, "NOT_ENOUGH_MANAGERS");
    // check that all signatures are valid and managers
    require(checkManagerSignatures(BouncerUtils.getMessageData(), _signature), "INVALID_SIGNATURES");

    if (_purpose == Types.Purpose.MANAGEMENT) {
      // we're dealing with management keys

      if (pendingManagerTimeouts[_keyId] > 0) {
        // if there's a pending manager, we only need minority to remove
        require(numSignatures >= _qualifiedManagerMinority(), "NOT_MINORITY");

        delete pendingManagerTimeouts[_keyId];
        emit PendingPurposeRemoved(_keyId, _purpose);

        return;
      }

      // must be operating on a valid key
      require(_hasPurpose(_keyId, _purpose), "KEY_PURPOSE_MISMATCH");
      // require a majority to remove
      require(numSignatures >= _simpleManagerMajority(), "NOT_MAJORITY");

      return _removeManager(_keyId);
    }

    return _removeKey(_keyId, _purpose);
  }

  function addOwner(
    address _owner,
    bytes _signature
  )
    external
  {
    require(_numSignatures(_signature) >= 1, "NOT_ENOUGH_MANAGERS");
    require(checkManagerSignatures(BouncerUtils.getMessageData(), _signature), "INVALID_SIGNATURES");

    _addOwner(_owner);
  }

  function removeOwner(
    address _prevOwner,
    address _owner,
    bytes _signature
  )
    external
  {
    require(_numSignatures(_signature) >= 1, "NOT_ENOUGH_MANAGERS");
    require(checkManagerSignatures(BouncerUtils.getMessageData(), _signature), "INVALID_SIGNATURES");

    _removeOwner(_prevOwner, _owner);
  }

  function promotePendingManager(bytes32 _keyId)
    external
  {
    require(pendingManagerTimeouts[_keyId] != 0, "IS_NOT_PENDING_MANAGER");
    // solium-disable-next-line security/no-block-members
    require(pendingManagerTimeouts[_keyId] < block.timestamp, "TIMEOUT_NOT_MET");

    delete pendingManagerTimeouts[_keyId];
    _addManager(_keyId);
  }

  // INTERNAL

  /**
   * @dev > 50% of managers
   * {0, 1} = 1
   * {2, 3} = 2
   * {4, 5} = 3
   * {6, 7} = 4
   */
  function _simpleManagerMajority()
    internal
    view
    returns (uint256)
  {
    return (numManagers / 2) + 1;
  }

  /**
   * @dev >= 33% of managers
   * {0, 1, 2} = 1
   * {3, 4, 5} = 1
   * {6, 7, 8} = 2
   */
  function _qualifiedManagerMinority()
    internal
    view
    returns (uint256)
  {
    if (numManagers <= 2) {
      return 1;
    }

    return (numManagers / 3);
  }

  function _hasPurpose(bytes32 _keyId, Types.Purpose _purpose)
    internal
    view
    returns (bool)
  {
    return roles[uint256(_purpose)].has(_keyId);
  }

  /**
   * @dev add a purpose to a key
   * @param _keyId key
   * @param _purpose the purpose
   */
  function _addPurpose(bytes32 _keyId, Types.Purpose _purpose)
    internal
  {
    roles[uint256(_purpose)].add(_keyId);
    emit PurposeAdded(_keyId, _purpose);
  }

  /**
   * @dev remove a purpose from a key
   * @param _keyId key
   * @param _purpose the purpose
   */
  function _removePurpose(bytes32 _keyId, Types.Purpose _purpose)
    internal
  {
    roles[uint256(_purpose)].remove(_keyId);
    emit PurposeRemoved(_keyId, _purpose);
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

  function _addManager(
    bytes32 _keyId
  )
    internal
    returns (bool)
  {
    _addKey(_keyId, Types.KeyType.ECDSA, Types.Purpose.MANAGEMENT);
    numManagers++;

    return true;
  }

  function _removeManager(
    bytes32 _keyId
  )
    internal
    returns (bool)
  {
    _removeKey(_keyId, Types.Purpose.MANAGEMENT);
    numManagers--;

    return true;
  }

  function _addKey(
    bytes32 _keyId,
    Types.KeyType _keyType,
    Types.Purpose _purpose
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

    // update purpose
    _addPurpose(_keyId, _purpose);

    return true;
  }

  function _removeKey(
    bytes32 _keyId,
    Types.Purpose _purpose
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

    _removePurpose(_keyId, _purpose);

    return true;
  }

  /**
   * @dev Should return whether the signature provided is valid for the provided data, hash
   * modified from GnosisSafe.sol
   * @param data That should be signed (this is passed to an external validator contract)
   * @param signatures Signature data that should be verified. Can be ECDSA signature, contract signature (EIP-1271) or approved hash.
   * @return a bool upon valid or invalid signature with corresponding _data
   */
  function checkManagerSignatures(bytes data, bytes signatures)
    internal
    returns (bool)
  {
    require(_validSignatureLength(signatures), "INVALID_SIGNATURE_LENGTH");

    uint256 numSignatures = _numSignatures(signatures);
    // There cannot be an owner with address 0.
    address lastManager = address(0);
    address currentManager;

    uint8 v;
    bytes32 r;
    bytes32 s;

    for (uint256 i = 0; i < numSignatures; i++) {
      // @TODO - replace with isSignedBy()
      (v, r, s) = signatureSplit(signatures, i);
      // If v is 0 then it is a contract signature
      if (v == 0) {
        // When handling contract signatures the address of the contract is encoded into r
        currentManager = address(r);
        bytes memory contractSignature;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
          // The signature data for contract signatures is appended to the concatenated signatures and the offset is stored in s
          contractSignature := add(add(signatures, s), 0x20)
        }
        if (!ISignatureValidator(currentManager).isValidSignature(data, contractSignature)) {
          return false;
        }
      } else {
        // Use ecrecover with the messageHash for EOA signatures
        // @TODO - instead of hashing the data, do we actually want to assume that it's a bytes32 hash?
        //  ^ that's probably what we want tbh
        currentManager = keccak256(abi.encodePacked(data))
          .toEthSignedMessageHash()
          .recover(abi.encodePacked(v, r, s));
      }

      bool isManager = _hasPurpose(currentManager.keyId(), Types.Purpose.MANAGEMENT);
      bool correctOrder = currentManager <= lastManager;
      if (correctOrder || !isManager) {
        return false;
      }

      lastManager = currentManager;
    }

    return true;
  }

  function _validSignatureLength(bytes _signature)
    internal
    pure
    returns (bool)
  {
    return (_signature.length % 65) == 0;
  }

  function _numSignatures(bytes _signature)
    internal
    pure
    returns (uint256)
  {
    return _signature.length / 65;
  }
}
