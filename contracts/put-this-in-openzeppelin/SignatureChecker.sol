pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ECRecovery.sol";

import "./ERC165Checker.sol";
import "./BytesConverter.sol";
import "./ISignatureValidator.sol";


library SignatureChecker {
  using BytesConverter for bytes;
  using ERC165Checker for address;

  function splitNextSignerAndSig(bytes memory _sig)
    internal
    pure
    returns (address addr, bytes memory result)
  {
    // bytes array has 32 bytes of length param at the beginning
    uint256 addrIndex = 32;
    uint256 sigIndex = 32 + 20;

    // solium-disable-next-line security/no-inline-assembly
    assembly {
      addr := mload(add(_sig, addrIndex))
      result := add(_sig, sigIndex)
    }
  }

  function isSignedBy(bytes _action, address _signer, bytes _sig)
    internal
    view
    returns (bool)
  {
    // if the signer address supports signature validation, ask for its permissions/validity
    // which means _sig can be anything
    if (_signer.supportsInterface(0x20c13b0b)) {
      return ISignatureValidator(_signer).isValidSignature(_action, _sig);
    }

    // otherwise make sure the hash was personally signed by the EOA account
    // which means _sig should be highly compacted vrs
    bytes32 signedHash = ECRecovery.toEthSignedMessageHash(_action.toBytes32(0));
    return _signer == ECRecovery.recover(signedHash, _sig);
  }
}
