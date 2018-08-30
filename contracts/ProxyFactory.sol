pragma solidity ^0.4.24;


/**
 * @title ProxyFactory
 * @dev Factory contract to deploy a constant proxy based on ERC-1167
 * https://github.com/ethereum/EIPs/blob/18ea1fc9a40cde083102cf6cd47e774fb9d61ee5/EIPS/eip-1167.md
 * @notice Original Source: https://gist.github.com/GNSPS/ba7b88565c947cfd781d44cf469c2ddb
 */
contract ProxyFactory {
  event ProxyDeployed(address _proxyAddress, address _targetAddress);

  function createProxy(address _target, bytes _data)
    internal
    returns (address)
  {
    address proxyContract = createProxyImpl(_target, _data);
    emit ProxyDeployed(proxyContract, _target);
    return proxyContract;
  }

  function createProxyImpl(address _target, bytes _data)
    internal
    returns (address proxyContract)
  {
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let contractCode := add(mload(0x40), 0x09)
      // ^ Find empty storage location using "free memory pointer" and add '9' to it so we don't overwrite the "_data" bytes array

      // this bytecode is from https://gist.github.com/GNSPS/ba7b88565c947cfd781d44cf469c2ddb
      // and should track the conversation at https://github.com/ethereum/EIPs/blob/18ea1fc9a40cde083102cf6cd47e774fb9d61ee5/EIPS/eip-1167.md
      mstore(add(contractCode, 0x0b), _target)
      // ^ Add target address, with a 11 bytes [i.e. 23 - (32 - 20)] offset to later accomodate first part of the bytecode
      mstore(sub(contractCode, 0x09), 0x000000000000000000603160008181600b9039f3600080808080368092803773)
      // ^ First part of the bytecode, shifted left by 9 bytes, overwrites left padding of target address
      mstore(add(contractCode, 0x2b), 0x5af43d828181803e808314602f57f35bfd000000000000000000000000000000)
      // ^ Final part of bytecode, offset by 43 bytes

      proxyContract := create(0, contractCode, 60) // total length 60 bytes
      if iszero(extcodesize(proxyContract)) {
        revert(0, 0)
      }

      // check if the _data.length > 0 and if it is forward it to the newly created contract
      let dataLength := mload(_data)
      if iszero(iszero(dataLength)) {
        if iszero(call(gas, proxyContract, 0, add(_data, 0x20), dataLength, 0, 0)) {
          revert(0, 0)
        }
      }
    }
  }
}
