pragma solidity ^0.4.24;


/**
 * @title KeyRoles
 */
library KeyRoles {
  struct Role {
    mapping (bytes32 => bool) bearer;
  }

  /**
   * @dev give a key access to this role
   */
  function add(Role storage _role, bytes32 _keyId) internal {
    _role.bearer[_keyId] = true;
  }

  /**
   * @dev remove a key's access to this role
   */
  function remove(Role storage _role, bytes32 _keyId) internal {
    _role.bearer[_keyId] = false;
  }

  /**
   * @dev check if a key has this role
   * @return bool
   */
  function has(Role storage _role, bytes32 _keyId)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_keyId];
  }
}
