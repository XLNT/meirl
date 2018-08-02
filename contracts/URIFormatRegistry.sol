pragma solidity ^0.4.24;


contract URIFormatRegistry {

  event URIFormatRegistered(bytes32 indexed key, string uriFormat);

  function registerURIFormat(bytes32 _key, string _uriFormat)
    internal
  {
    emit URIFormatRegistered(_key, _uriFormat);
  }
}
