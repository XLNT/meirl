# meirl

> it me, irl

`meirl` is a self-soverign identity implementation using counterfactual contract identities and Gnosis Safe.

This means it:

+ has free instantiation costs; onboarding users is completely off-chain using counterfactual instantiation
  - simply, just generate a normal Ethereum keypair and then assume an identity contract exists
+ has guaranteed standard compliance via identity factories and proxy-of-proxy upgradability,
+ delegated and gasless tx using MetaTx
  - this was using Bouncer from OpenZeppelin, but in the aim of least concerns, we'll use the safe's custom signature protocol
+ uses "verifiable claims" metaphor for SSI attestations, and
  - virtual-chain style event emissions on deterministrically deployed claim registry
+ uses role based access control for key management.

In our case, the counterfactual instantiation is simply a user signing any data; this proves that they have the ability to control an identity contract, in the future, based on that public key.

When using a single key, it's possible to authenticate multiple devices using a two-factor-confirm user experience ala WalletConnect (but over a p2p network like Whisper or webp2p instead of a centralized bridge server, yeah?).

Once a user wants to evolve to caring for a fully self-sovereign identity contract (primarily to support multiple independent devices and keys beyond the single, origin key or to interact with non-ecosystem contracts), they can deploy their identity fully, which costs 66k gas, or about 5 cents at 1gwei and $450 ETH.

ENS name grants can be cached off-chain and then committed on-chain as part of the identity deploy process.

DIDs might look like

`did:xlnt-id:bytes` => `bytes.xlnt-id.eth` => `contract address`

```

[CounterfactualIdentityFactory]     [Aragon DAO]
  | (creates)                          | (manages)
  v                                    v                  |-> [Identity (Gnosis Safe +) v1.0]
[Identity (Proxy)] ------------> [AdminUpgradabilityProxy] -> [Identity (Gnosis Safe +) v2.0]
  ^ 1-per-user                     ^ single, constant     |-> [Identity (Gnosis Safe +) v3.0]
  ^ counterfactual addr            ^ deterministic addr
                                   ^ upgradable
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

## Recovery

1. one management key; nothing
2. two management keys, nothing
3. three or more management keys:
- a simple majority of management keys can add a new management key, which is immediately in effect
- a qualified minority of management keys can add another management key, but there's a `timeout` before it's usable
- a simple majority of management keys is required to remove a management key, and is immediately effective

So basically a simple majority of your management keys must be compromised before you lose control of your identity. You can tolerate a qualified minority of management keys being compromised for up to `timeout` time. So, if you've got three keys, you can tolerate 1 of your devices getting compromised and reject the old key within the 24/48 hours, before any new, fraudulent keys that the attacker may add become usable.

## @TODO

+ Replace counterfactual registry with ENS resolver
+ if the ENS registry isn't 820-deployed, use deterministic address proxy contract to implement `resolve()` for the specific chain.
+ use blocknum-chained events
