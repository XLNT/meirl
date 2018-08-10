pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ECRecovery.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

import "zos-lib/contracts/migrations/Migratable.sol";

import "../../put-this-in-openzeppelin/BytesConverter.sol";
import "../../put-this-in-openzeppelin/BouncerUtils.sol";
import "../../put-this-in-openzeppelin/SignatureValidator.sol";
import "../../put-this-in-openzeppelin/SignatureChecker.sol";

import "../../util/Types.sol";
import "../../interfaces/IIdentity.sol";

import "./Executor01.sol";
import "./KeyManager01.sol";

/**
 * @title IdentityImplementation01
 * @dev Implements identity by managing keys, executing functions, and validating signatures.
 */
contract IdentityImplementation01 is IIdentity, SignatureValidator, Migratable, KeyManager01, Executor01 {
  using SignatureChecker for bytes;

  uint256 public nonce = 0;

  /**
   * @dev Initialize Identity by initializing KeyManager
   */
  function initialize(bytes32 _keyId, Types.KeyType _keyType, bytes8 _purposes)
    public
    isInitializer("IdentityImplementation", "01")
  {
    KeyManager01.initialize(_keyId, _keyType, _purposes);
  }

  /**
   * @dev Allows to execute a MetaTx confirmed by required number of owners and then pays the delegate that submitted the transaction.
   * @notice The fees are always transfered, even if the MetaTx fails.
   * @param _op Operation type of MetaTx
   * @param _to Destination address of MetaTx
   * @param _value Ether value of MetaTx
   * @param _data Data payload of MetaTx
   * @param _gas Gas that should be used for the MetaTx
   * @param _gasPrice Gas price that should be used for the payment calculation.
   * @param _gasToken Token address (or 0 if ETH) that is used for the payment.
   * @param _sig Bouncer signature for transaction
   */
  function execute(
    Types.Operation _op,
    address _to,
    uint256 _value,
    bytes _data,
    uint256 _gas,
    uint256 _gasPrice,
    address _gasToken,
    bytes _sig
  )
    public
    returns (bool)
  {
    uint256 startGas = gasleft();
    require(isValidTicket(_sig));
    // we can trust arguments

    nonce = nonce + 1;

    require(gasleft() >= _gas, "Not enough gas to execute safe transaction");
    bool success = _execute(_op, _to, _value, _data, _gas);
    if (!success) {
      emit ExecutionFailed(BouncerUtils.getHashOfMessageData(address(this)));
    }

    // We transfer the calculated tx costs to the tx.origin to avoid sending it to intermediate contracts that have made calls
    if (_gasPrice > 0) {
      uint256 gasCost = (startGas - gasleft());
      uint256 amount = gasCost * _gasPrice;
      if (_gasToken == address(0)) {
        // solium-disable-next-line security/no-tx-origin,security/no-send
        require(tx.origin.send(amount), "Could not pay gas costs with ether");
      } else {
        // solium-disable-next-line security/no-tx-origin
        require(ERC20(_gasToken).transfer(tx.origin, amount), "Could not pay gas costs with token");
      }
    }

    return success;
  }

  /**
    * @dev estimate a MetaTx
    *  This method is only meant for estimation purpose, therfore two different protection mechanism against execution in a transaction have been made:
    *  1) The method can only be called from this contract
    *  2) The response is returned with a revert
    *  When estimating, set `from` to the address of the identity.
    * @param _op Operation type of MetaTx
    * @param _to Destination address of MetaTx
    * @param _value Ether value of MetaTx
    * @param _data Data payload of MetaTx
    * @return Estimate of the MetaTx itself
    */
  function estimateGas(
    Types.Operation _op,
    address _to,
    uint256 _value,
    bytes _data
  )
    public
    authorized
    returns (uint256)
  {
    uint256 startGas = gasleft();
    // We don't provide an error message here, as we use it to return the estimate
    require(_execute(_op, _to, _value, _data, gasleft()));
    uint256 requiredGas = startGas - gasleft();
    // Convert response to string and return via error message
    revert(string(abi.encodePacked(requiredGas)));
  }

  /**
   * @dev An action is valid iff the _sig of the _action is from an key with the ACTION purpose
   * @param _action action that is signed
   * @param _sig [[address] [address] [...]] <address> <v> <r> <s>
   */
  function isValidSignature(
    bytes _action,
    bytes _sig
  )
    external
    view
    returns (bool)
  {
    (address nextSigner, bytes memory sig) = _sig.splitNextSignerAndSig();
    // permission
    bytes32 keyId = KeyUtils.idForAddress(nextSigner);
    bool hasPermission = keyHasPurpose(keyId, PURPOSE_ACTION);

    // validity
    bool isValid = _action.isSignedBy(nextSigner, sig);

    return hasPermission && isValid;
  }

  function isValidTicket(bytes _sig)
    internal
    view
    returns (bool)
  {
    bytes32 msgDataHash = BouncerUtils.getHashOfMessageData(address(this));
    return BytesConverter.toBytes(msgDataHash).isSignedBy(address(this), _sig);
  }
}
