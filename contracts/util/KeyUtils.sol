pragma solidity ^0.4.24;


library KeyUtils {
  function keyId(address _address)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(_address));
  }
}
