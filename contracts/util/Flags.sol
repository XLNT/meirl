pragma solidity ^0.4.24;


library Flags {

  function makeFlagSet(bytes8[] _flags)
    pure
    internal
    returns (bytes8)
  {
    bytes8 flagSet;

    for (uint8 i = 0; i < _flags.length; i++) {
      flagSet = addFlag(flagSet, _flags[i]);
    }

    return flagSet;
  }

  function hasFlag(bytes8 _field, bytes8 _flag)
    pure
    internal
    returns  (bool)
  {
    return _flagIntersection(_field, _flag) != 0;
  }

  function addFlag(bytes8 _field, bytes8 _flag)
    pure
    internal
    returns (bytes8)
  {
    return _field | _flag;
  }

  function _flagIntersection(bytes8 _field, bytes8 _flags)
    pure
    internal
    returns (bytes8)
  {
    return (_field & _flags);
  }
}
