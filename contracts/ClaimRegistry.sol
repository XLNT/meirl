pragma solidity ^0.4.24;

import "./URIFormatRegistry.sol";


contract ClaimRegistry is URIFormatRegistry {

  // I'm not yet convinced that any contract-based access will ever happen here
  // mapping(address => mapping(address => mapping(bytes32 => bytes32))) public registry;


  // claims to not explicitely include time-based expiry information, because I was convinced by
  // https://github.com/ethereum/EIPs/issues/735#issuecomment-362802104
  // claims are not explicitely timestamped because that information is available at ~blocktime resolution
  // as a side effect of block timestamp. This means that specifying expiry in increments more fine than ~15s on mainnet
  // simply isn't possible. I'd argue that this is _fine_ and issuers can be conservative if it really matters.
  // likewise, using `now` within a solidity contract isn't that precise at all, si I'd argue it's useless to include.
  event ClaimIssued(
    address indexed issuer,
    address indexed subject,
    bytes32 indexed key,
    bytes value,
    string uri
  );

  // claimId is soliditySha3(issuer, subject, key, value)
  // revoke specific claim from `issuer` against `subject` about `key` with `value`
  event ClaimRevoked(
    address indexed issuer,
    bytes32 indexed claimId
  );

  // claimId is soliditySha3(issuer, subject, key)
  // revoke all claims from `issuer` against `subject` about `key`
  event ClaimRevokedBySubjectAndKey(
    address indexed issuer,
    bytes32 indexed claimId
  );

  // claimId is soliditySha3(issuer, subject)
  // revoke all claims from `issuer` against `subject`
  event ClaimRevokedBySubject(
    address indexed issuer,
    bytes32 indexed claimId
  );


  function issue(address _subject, bytes32 _key, bytes _value, string _uri)
    public
  {
    emit ClaimIssued(
      msg.sender,
      _subject,
      _key,
      _value,
      _uri
    );
  }

  function revoke(bytes32 _claimId)
    public
  {
    emit ClaimRevoked(msg.sender, _claimId);
  }

  function revokeBySubjectAndKey(bytes32 _claimId)
    public
  {
    emit ClaimRevokedBySubjectAndKey(msg.sender, _claimId);
  }

  function revokeBySubject(bytes32 _claimId)
    public
  {
    emit ClaimRevokedBySubject(msg.sender, _claimId);
  }

  // _uriFormat follows ___ templating and supports argument :claimId
  // rep.dot.af/claims/:claimId
  // for each claim they care about, clients should hash the issuer address to get the URIFormat key
  // and then look up the most recent URIFormatRegistered() event
  // and use that to format addresses.
  // the uri parameter is provided for claim-specific uri overrides
  function registerIssuerURIFormat(string _uriFormat)
    public
  {
    registerURIFormat(msg.sender, _uriFormat);
  }
}
