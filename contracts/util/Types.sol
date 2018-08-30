pragma solidity 0.4.24;


contract Types {
  enum KeyType {
    INVALID,
    ECDSA
  }

  enum Purpose {
    INVALID,
    MANAGEMENT, // add & subtract authorized keys
    TRANSACTION,  // send transactions via Identity
    CLAIM,  // publish claims on behalf of the Identity
    ENCRYPTION,  // encrypt data on behalf of the Identity
    OFF_CHAIN_AUTHORIZATION  // access off-chain resources on behalf of the Identity
  }

  struct Key {
    // the keccak256() of the public key
    bytes32 id;
    // the type of key used
    KeyType keyType;
  }
}
