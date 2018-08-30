pragma solidity ^0.4.24;

import "../util/Types.sol";
import "./IKeyManager.sol";


/**
 * @title IIdentity
 * @dev Identity Interface
 * @author Matt Condon - <matt@xlnt.co>
 */
contract IIdentity is IKeyManager {
  event ExecutionFailed(bytes32 txHash);

  function initialize(address _initialKey) external;
  function nonce() external returns (uint256);


}
