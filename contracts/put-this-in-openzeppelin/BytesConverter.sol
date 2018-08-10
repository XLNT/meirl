pragma solidity ^0.4.24;


library BytesConverter {
  function toBytes32(bytes memory _arg, uint256 _index)
    public
    pure
    returns (bytes32 res)
  {
    // Arrays are prefixed by a 32 byte length parameter
    uint256 index = _index + 32;

    require(
      _arg.length >= index,
      "GREATER_OR_EQUAL_TO_32_LENGTH_REQUIRED"
    );

    // solium-disable-next-line security/no-inline-assembly
    assembly {
      res := mload(add(_arg, index))
    }
  }

  function toBytes(bytes32 _arg)
    public
    pure
    returns (bytes)
  {
    return abi.encodePacked(_arg);
  }
}
