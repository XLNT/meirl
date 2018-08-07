pragma solidity 0.4.24;

import "../../util/Types.sol";


/**
 * @title Executor - A contract that can execute transactions
 * @author Matt Condon - <matt@XLNT.co>
 * @author Richard Meissner - <richard@gnosis.pm>
 * @notice Original Source: https://github.com/gnosis/safe-contracts/blob/master/contracts/Executor.sol
 */
contract Executor01 {

  event ContractCreated(address _newContract);

  function _execute(
    Types.Operation _operation,
    address _to,
    uint256 _value,
    bytes _data,
    uint256 _gas
  )
    internal
    returns (bool success)
  {
    if (_operation == Types.Operation.CALL) {
      success = executeCall(_to, _value, _data, _gas);
    } else if (_operation == Types.Operation.DELEGATECALL) {
      success = executeDelegateCall(_to, _data, _gas);
    } else if (_operation == Types.Operation.CREATE) {
      address newContract = executeCreate(_data);
      success = newContract != 0;
      emit ContractCreated(newContract);
    }
  }

  function executeCall(
    address _to,
    uint256 _value,
    bytes _data,
    uint256 _gas
  )
    internal
    returns (bool success)
  {
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := call(_gas, _to, _value, add(_data, 0x20), mload(_data), 0, 0)
    }
  }

  function executeDelegateCall(
    address _to,
    bytes _data,
    uint256 _gas
  )
    internal
    returns (bool success)
  {
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := delegatecall(_gas, _to, add(_data, 0x20), mload(_data), 0, 0)
    }
  }

  function executeCreate(
    bytes _data
  )
    internal
    returns (address newContract)
  {
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      newContract := create(0, add(_data, 0x20), mload(_data))
    }
  }
}
