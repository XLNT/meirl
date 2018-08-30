pragma solidity ^0.4.24;

import "gnosis-safe/contracts/GnosisSafe.sol";
import "zos-lib/contracts/migrations/Migratable.sol";

import "../../util/Types.sol";
import "./KeyManager01.sol";


contract Identity01 is Migratable, IIdentity, GnosisSafe, KeyManager01 {

  function initialize(address _initialKey)
    public
    isInitializer("Identity", "0")
  {
    // first, initialize the GnosisSafe with this original key and a single threshold
    setup([_initialKey], 1, 0, 0);

    // then, initialize the KeyManager with a single management key
    KeyManager.initialize(
      KeyUtils.idForAddress(_initialKey),
      Types.KeyType.ECDSA,
      [Types.Purpose.MANAGEMENT]
    );
  }
}
