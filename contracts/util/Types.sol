pragma solidity 0.4.24;


contract Types {
  enum KeyType {
    INVALID,
    ECDSA
  }

  enum Purpose {
    INVALID,
    MANAGEMENT, // can add & subtract authorized keys

    AUTHENTICATION, // authenticate as this identity off-chain (including JWTs)
    CLAIM,  // publish on-chain verifiable claims on behalf of the Identity
    ENCRYPTION  // these keys should be able to read data encrypted for this identity
  }

  struct Key {
    // the keccak256() of the public key
    bytes32 id;
    // the type of key used
    KeyType keyType;
  }
}
