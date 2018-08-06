pragma solidity 0.4.24;


contract Types {
  enum Operation {
    INVALID,
    CALL,
    DELEGATECALL,
    CREATE
  }

  enum KeyType {
    INVALID,
    ECDSA
  }

  struct Key {
    // the keccak256() of the public key
    bytes32 id;
    // the type of key used
    KeyType keyType;
    // the purposes of the key
    bytes8 purposes;
  }
}
