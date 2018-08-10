pragma solidity ^0.4.24;


interface ISignatureValidator {
  /**
   * @dev verifies that a signature for an action is valid
   * @param _action action that is signed
   * @param _sig the provided signature
   * @return bool validity of the action and the signature
   */
  function isValidSignature(
    bytes _action,
    bytes _sig
  )
    external
    view
    returns (bool);
}
