pragma solidity ^0.4.24;

/**
 * @title IActionValidator
 * @dev https://github.com/ethereum/EIPs/issues/1271
 */
interface IActionValidator {
  function isValidAction(bytes32 _action, bytes _signature)
    view
    external
    returns (bool isValid);
}
