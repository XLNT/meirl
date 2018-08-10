pragma solidity ^0.4.24;

import "./ISignatureValidator.sol";
import "openzeppelin-solidity/contracts/introspection/ERC165.sol";
import "openzeppelin-solidity/contracts/introspection/SupportsInterfaceWithLookup.sol";


contract SignatureValidator is ERC165, SupportsInterfaceWithLookup, ISignatureValidator {
  bytes4 internal constant InterfaceId_SignatureValidator = 0x20c13b0b;
  /**
   * 0x20c13b0b ===
   *   bytes4(keccak256('isValidSignature(bytes,bytes)'))
   */


  constructor()
    public
  {
    _registerInterface(InterfaceId_SignatureValidator);
  }
}
