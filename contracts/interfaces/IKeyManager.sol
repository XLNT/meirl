pragma solidity ^0.4.24;

import "../util/Types.sol";


interface IKeyManager {

  // READ

  function getKey(
    bytes32 _keyId
  )
    external
    view
    returns (
      bytes32 keyId,
      Types.KeyType keyType
    );

  function keyHasPurpose(
    bytes32 _keyId,
    Types.Purpose _purpose
  )
    external
    view
    returns (
      bool hasPurpose
    );

  // WRITE

  function addKey(
    bytes32 _keyId,
    Types.KeyType _keyType,
    uint256[] _purposes  // @TODO - why can't this be Types.Purpose[]?
  )
    external
    returns (
      bool success
    );

  function removeKey(
    bytes32 _keyId
  )
    external
    returns (
      bool success
    );
}


interface IKeyManagerEnumerable {

  // READ

  function totalKeys()
    external
    view
    returns (
      uint256 keyCount
    );

  function keyByIndex(
    uint256 _index
  )
    external
    view
    returns (
      bytes32 keyId
    );
}
