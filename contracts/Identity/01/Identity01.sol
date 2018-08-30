pragma solidity ^0.4.24;

import "gnosis-safe/contracts/GnosisSafe.sol";
import "zos-lib/contracts/migrations/Migratable.sol";

import "../../interfaces/IIdentity.sol";
import "../../util/Types.sol";
import "./KeyManager01.sol";


contract Identity01 is Migratable, IIdentity, KeyManager01, GnosisSafe {

  address[] internal fuckSolidityKeys;
  Types.Purpose[] internal fuckSolidityPurposes;


  function initialize(address _initialKey)
    public
    isInitializer("Identity", "0")
  {
    // first, initialize the GnosisSafe with this original key and a single threshold
    fuckSolidityKeys.push(_initialKey);
    bytes memory data;
    setup(
      fuckSolidityKeys, // this key
      1,           // threshold
      address(0),  // nowhere
      data         // nothing
    );

    // then, initialize the KeyManager with a single management key
    fuckSolidityPurposes.push(Types.Purpose.MANAGEMENT);
    KeyManager01.initialize(
      KeyUtils.idForAddress(_initialKey),
      Types.KeyType.ECDSA,
      fuckSolidityPurposes
    );
  }
}
