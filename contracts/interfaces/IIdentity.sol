pragma solidity ^0.4.24;

import "../util/Types.sol";


/**
 * @title IIdentity
 * @dev Identity Interface
 * @author Matt Condon - <matt@xlnt.co>
 * @author Stefan George - <stefan@gnosis.pm>
 * @author Richard Meissner - <richard@gnosis.pm>
 * @author Ricardo Guilherme Schmidt - (Status Research & Development GmbH) - Gas Token Payment
 * @notice Original Source: https://github.com/gnosis/safe-contracts/blob/master/contracts/GnosisSafePersonalEdition.sol
 */
interface IIdentity {
  event ExecutionFailed(bytes32 txHash);

  function initialize(bytes32 _keyId, Types.KeyType _keyType, bytes8 _purposes) external;
  function nonce() external returns (uint256);


}
