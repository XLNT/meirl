pragma solidity 0.4.24;


/**
 * @title SelfAuthorized
 * @author Matt Condon - <matt@XLNT.co>
 * @author Richard Meissner - <richard@gnosis.pm>
 * @notice Original Source: https://github.com/gnosis/safe-contracts/blob/master/contracts/SelfAuthorized.sol
 */
contract SelfAuthorized {
  /**
   * @dev gate access to function by the contract itself
   * useful for making sure that modifications go through the access control of the contract itself
   */
  modifier authorized() {
    require(msg.sender == address(this));
    _;
  }
}
