pragma solidity ^0.4.24;

import "../util/Types.sol";


interface IIdentity {
  function initialize(bytes32 _keyId, Types.KeyType _keyType, bytes8 _purposes) external;
}
