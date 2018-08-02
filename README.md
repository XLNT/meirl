# boku

> I

Boku is a self-soverign identity implementation using counterfactual contract identities and Bouncer transactions built on zos.

This means it:

+ has "free" instantiation costs; onboarding users is "free",
+ has guaranteed standard compliance via identity factories and proxy-of-proxy upgradability,
+ universal upgradability via ZOS
+ delegated and gasless tx using the Bouncer pattern,
+ uses "verifiable claims" metaphor for SSI attestations, and
+ uses role-based access control for key management.

In our case, the counterfactual instantiation is simply a user signing any data; this proves that they have the ability to deploy a contract, in the future, based on that public key. Operating on-chain as that identity requires opt-in contracts ala MetaTx, but because they are

When using a single key, it's possible to authenticate multiple devices using a two-factor-confirm user experience ala WalletConnect.

Once a user wants to evolve to caring for a fully self-sovereign identity contract (primarily to support multiple independent devices and keys beyond the single, origin key or to interact with non-ecosystem contracts), they can deploy their identity fully.

dot is totally in control of name grants, so we can store that shit off-chain and then commit it on-chain once they evolve.


DIDs might look like

`did:xlnt-id:bytes` => `bytes.xlnt-id.eth` => `contract address`

if the ENS registry isn't 820-deployed, use deterministic address proxy contract to implement `resolve()` for the specific chain.

```

[CounterfactualIdentityManager]
    v (creates)
[IdentityProxy] -> [IdentityImplementationProxy] -> [Identity]
^ n users             ^ single, constant                   ^ upgradable via governance
^ deterministic addr  ^ deterministic addr, upgradable
```


The process goes like:
- user generated keypair on-device, and tells boku server their public key
- we can calculate the eventual identity proxy address by
  1. constructing the bytecode, which includes a constructor telling the contract about its first owner (the original keypair)
    - should use 66785 gas and have a gasprice of :originalGasPrice with enough buffer to last
  2. constructing the raw transaction
  2. recovering the pseudo-signature as above
  3. and then calculating the contract address using that sender
    - `web3.utils.sha3(RLP.encode([ address, 0x0 ])).substr(-40)`
  4. and begin counterfactually interacting with that identity
  5. When the user wants to actually create their identity, we
    1. send exactly :proxyGasCost * :originalGasPrice to :sender
    2. submit the signed transaction to the network, consuming all of the ether in that account


---

convert the logic in https://github.com/gnosis/safe-contracts/blob/master/contracts/DelegateConstructorProxy.sol
to assembly so it can be appended to the default bytecode as a constructor

```
contract DelegateConstructorProxy {

    /// @dev Constructor function sets address of master copy contract.
    /// @param _masterCopy Master copy address.
    /// @param initializer Data used for a delegate call to initialize the contract.
    constructor(address _masterCopy, bytes initializer)
        public
    {
        if (initializer.length > 0) {
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                let success := delegatecall(sub(gas, 10000), _masterCopy, add(initializer, 0x20), mload(initializer), 0, 0)
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize)
                if eq(success, 0) { revert(ptr, returndatasize) }
            }
        }
    }
}
```
