pragma solidity ^0.4.24;


contract URIFormatRegistry {

  event URIFormatRegistered(address indexed issuer, string uriFormat);

  function registerURIFormat(address _issuer, string _uriFormat)
    internal
  {
    emit URIFormatRegistered(_issuer, _uriFormat);
  }
}
