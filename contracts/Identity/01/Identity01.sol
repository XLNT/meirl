pragma solidity ^0.4.24;

import "zos-lib/contracts/migrations/Migratable.sol";

import "../../interfaces/IIdentity.sol";
import "../../interfaces/IKeyManager.sol";
import "../../util/Types.sol";
import "./KeyManager01.sol";


contract Identity01 is Migratable, IIdentity, KeyManager01 {

  // because you can't inline dynamic bytes in solidity (??)
  address[] private fuckSolidityKeys;


  function initialize(address _initialKey)
    public
    isInitializer("Identity", "0")
  {
    // first, initialize the GnosisSafe with this original key and a single threshold
    fuckSolidityKeys.push(_initialKey);
    bytes memory data;
    GnosisSafe.setup(
      fuckSolidityKeys,  // initial key
      1,                 // threshold
      address(0),        // nowhere
      data               // nothing
    );

    // then, initialize the KeyManager with a single management key
    KeyManager01.initialize(_initialKey);
  }
}
