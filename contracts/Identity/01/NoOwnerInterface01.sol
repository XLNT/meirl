pragma solidity ^0.4.24;

import "gnosis-safe/contracts/base/OwnerManager.sol";


contract NoOwnerInterface01 is OwnerManager {
  // Nuke the public interface of OwnerManager

  function addOwnerWithThreshold(address, uint256)
    public
  {
    require(false, "USE_KEYMANAGER");
  }
  function removeOwner(address, address, uint256)
    public
  {
    require(false, "USE_KEYMANAGER");
  }
  function swapOwner(address, address, address)
    public
  {
    require(false, "USE_KEYMANAGER");
  }
  function changeThreshold(uint256)
    public
  {
    require(false, "USE_KEYMANAGER");
  }

  // reimplement public functions as internal
  function _addOwner(address owner)
    internal
  {
    // Owner address cannot be null.
    require(owner != 0 && owner != SENTINEL_OWNERS, "Invalid owner address provided");
    // No duplicate owners allowed.
    require(owners[owner] == 0, "Address is already an owner");
    owners[owner] = owners[SENTINEL_OWNERS];
    owners[SENTINEL_OWNERS] = owner;
    ownerCount++;
    emit AddedOwner(owner);
  }

  function _removeOwner(address prevOwner, address owner)
    internal
  {
    // Only allow to remove an owner, if threshold can still be reached.
    require(ownerCount - 1 >= threshold, "New owner count needs to be larger than new threshold");
    // Validate owner address and check that it corresponds to owner index.
    require(owner != 0 && owner != SENTINEL_OWNERS, "Invalid owner address provided");
    require(owners[prevOwner] == owner, "Invalid prevOwner, owner pair provided");
    owners[prevOwner] = owners[owner];
    owners[owner] = 0;
    ownerCount--;
    emit RemovedOwner(owner);
  }
}
