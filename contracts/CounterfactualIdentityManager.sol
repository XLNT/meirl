pragma solidity ^0.4.24;

import "./put-this-in-openzeppelin/BouncerUtils.sol";

import "./util/Types.sol";
import "./util/KeyUtils.sol";
import "./util/Flags.sol";

import "./interfaces/IIdentity.sol";
import "./ProxyFactory.sol";


/**
 * @title CounterfactualIdentityManager
 * @dev The CounterfactualIdentityManager counterfactually manages identities.
 * (but actually) what that means is that any keypair can be assumed to have a future
 * (but not yet deployed) identity contract available.
 */
contract CounterfactualIdentityManager is ProxyFactory {
  event ContractCreated(bytes32 indexed cfAddress, address deployedAddress);


  // see KeyManager for details
  // @TODO - remove after https://github.com/ethereum/solidity/issues/1290
  bytes8 constant public PURPOSE_GOD = bytes8(~0); // [...] 11111111 11111111 11111111 11111111

  /**
   * Map from counterfactual address to Ethereum address.
   */
  mapping(bytes32 => address) registry;

  address public identityImplementation = address(0);

  constructor(address _identityImplementation)
    public
  {
    identityImplementation = _identityImplementation;
  }

  // point to the proxy contract address or 0x0
  // @TODO(shrugs) - replace this with ENS
  function resolve(bytes32 _cfAddress)
    view
    public
    returns (address)
  {
    return registry[_cfAddress];
  }

  // convert my account from a single keypair to a contract identity
  function deploy()
    public
  {
    _deploy(msg.sender);
  }

  // this is the only valid use-case of delegate-specific function calls
  // outside of in-ecosystem features
  // all other delegated calls should be abstracted to the identity contract
  // notice: the _sig parameter is implicitely required by BouncerUtils#signerOfMessageData
  function deployFor(address _origAddress, bytes)
    public
  {
    // @TODO - should this be
    // _delegate.isValidSignature(BouncerUtils.getMessageData(), _sig)
    // this contract is the delegate
    // and implements isValidSignature by checking that the signer of the message is the _origAddress above
    require(BouncerUtils.signerOfMessageData(address(this)) == _origAddress);

    // the sender has signed the calldata that this contract received, so we're good to go
    _deploy(_origAddress);
  }

  function _deploy(address _origAddress)
    internal
  {
    bytes32 cfAddress = cfAddressOf(_origAddress);
    // @TODO — deploy proxy
    bytes memory data;
    address identityAddress = createProxyImpl(identityImplementation, data);
    // initialize proxy (replace with _data in createProxyImpl?)
    IIdentity(identityAddress).initialize(
      KeyUtils.idForAddress(_origAddress),
      Types.KeyType.ECDSA,
      PURPOSE_GOD
    );

    // @TODO(shrugs) - replace with ENS registry at xlnt-id
    registry[cfAddress] = identityAddress;

    emit ContractCreated(cfAddress, identityAddress);
  }

  function cfAddressOf(address _origAddress)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(byte(0x19), _origAddress));
  }
}
