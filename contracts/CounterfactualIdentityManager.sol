pragma solidity ^0.4.24;

import "./put-this-in-openzeppelin/BouncerUtils.sol";

import "./util/Types.sol";
import "./util/KeyUtils.sol";

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

  /**
   * Map from counterfactual address to Ethereum address.
   * replace with ENS
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
    public
    view
    returns (address)
  {
    return registry[_cfAddress];
  }

  /**
   * @dev Deploy an identity for an Ethereum EOA address.
   * @notice Anyone can deploy anyone else's identity contract, but that doesn't really do anything bad
   * because then you just paid the gas for them, so you're good to go.
   */
  function deploy(address _origAddress)
    public
  {

    _deploy(_origAddress);
  }

  function _deploy(address _origAddress)
    internal
  {
    bytes32 cfAddress = cfAddressOf(_origAddress);
    require(resolve(cfAddress) != address(0), "IDENTITY_ALREADY_DEPLOYED");

    // construct empty bytes (any better way of doing this?)
    bytes memory data;

    // deploy proxy via factory
    address identityAddress = createProxy(identityImplementation, data);

    // initialize proxy with original address
    IIdentity(identityAddress).initialize(_origAddress);

    // @TODO(shrugs) - replace with ENS
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
