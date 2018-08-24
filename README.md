# boku

> I

Boku is a self-soverign identity implementation using counterfactual contract identities and Bouncer transactions built on zos.

This means it:

+ has "free" instantiation costs; onboarding users is completely off-chain using counterfactual instantiation
+ has guaranteed standard compliance via identity factories and proxy-of-proxy upgradability,
+ universal upgradability via ZOS
+ delegated and gasless tx using the Bouncer pattern,
+ uses "verifiable claims" metaphor for SSI attestations, and
+ uses bitwise flag access control for key management.

In our case, the counterfactual instantiation is simply a user signing any data; this proves that they have the ability to deploy a contract, in the future, based on that public key. Operating on-chain as that identity requires opt-in contracts ala MetaTx, but because they are part of an ecosystem, that's ok.

When using a single key, it's possible to authenticate multiple devices using a two-factor-confirm user experience ala WalletConnect (but over a p2p network instead of a centralized bridge server).

Once a user wants to evolve to caring for a fully self-sovereign identity contract (primarily to support multiple independent devices and keys beyond the single, origin key or to interact with non-ecosystem contracts), they can deploy their identity fully, which costs 66k gas, or about 5 cents at 1gwei and $450 ETH.

ENS name grants can be cached off-chain and then committed on-chain as part of the identity deploy process.

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


The [deterministic address process](https://github.com/ethereum/EIPs/issues/820) goes like:
1. constructing the bytecode
2. constructing the raw transaction using that bytecode and a high :originalGasPrice
  - v = `27`
  - r = `0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798`
  - s = `:arbitrary` (`0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa`)
3. recovering the signer from pseudo-signature
4. when we want to actually deploy the bytecode, send exactly :proxyGasCost * :originalGasPrice to :sender
5. then submit the signed transaction to the network, consuming all of the ether in that account

## @TODO

+ Replace counterfactual registry with ENS resolver
+ Deploy a [MultiSend](https://github.com/gnosis/safe-contracts/blob/master/contracts/libraries/MultiSend.sol)
+ Re-implement Bouncer (public facing execute interface) for Identity (using KeyManager permissions)
