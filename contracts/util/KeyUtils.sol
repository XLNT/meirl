pragma solidity ^0.4.24;


library KeyUtils {
  function idForAddress(address _address)
    pure
    internal
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(_address));
  }
}
