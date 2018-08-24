pragma solidity ^0.4.24;

import "../util/Flags.sol";


contract FlagsMock {
  using Flags for bytes8;

  bytes8 private field;

  constructor(bytes8 _field)
    public
  {
    field = _field;
  }

  function getField()
    public
    view
    returns (bytes8)
  {
    return field;
  }

  function makeFlagSet(bytes8[] _flags)
    public
    pure
    returns (bytes8)
  {
    return Flags.makeFlagSet(_flags);
  }

  function hasFlag(bytes8 _flag)
    public
    view
    returns  (bool)
  {
    return field.hasFlag(_flag);
  }

  function addFlag(bytes8 _flag)
    public
  {
    field = field.addFlag(_flag);
  }

  function removeFlag(bytes8 _flag)
    public
  {
    field = field.removeFlag(_flag);
  }
}
