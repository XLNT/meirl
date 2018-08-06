pragma solidity ^0.4.24;


interface IKeyManager {

  // READ

  function getKey(
    bytes32 _keyId
  )
    view
    external
    returns(
      bytes8 purposes,
      uint256 keyType,
      bytes32 key
    );

  function keyHasPurpose(
    bytes32 _keyId,
    bytes8 _purpose
  )
    view
    external
    returns(
      bool hasPurpose
    );

  // WRITE

  function addKey(
    bytes32 _keyId,
    uint256 _keyType,
    bytes8 _purposes
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

  function removeKeyPurposes(
    bytes32 _keyId,
    bytes8 _purposes
  )
    external
    returns (
      bool success
    );
}


interface IKeyManagerEnumerable {
  function totalKeys()
    view
    external
    returns (bool keyCount);

  function keyByIndex(uint256 _index)
    view
    external
    returns (bytes32 keyId);
}
