const pify = require("pify");
const peth = pify(web3.eth);

const Transaction = require("eth-lib/lib/transaction");
const Bytes = require("eth-lib/lib/bytes");
const RLP = require("eth-lib/lib/rlp");

const deployContract = async (data, extra = {}) => {
  const res = await peth.sendTransaction({ ...extra, data });
  const receipt = await peth.getTransactionReceipt(res);

  return receipt.contractAddress;
};

const deterministicallyDeploy = async (
  TruffleContractInstance,
  args = [],
  gasPrice = web3.toHex(web3.toWei(100, "gwei")),
  extra
) => {
  // console.log("gasPrice", gasPrice);

  // construct bytecode
  const bytecode = web3.eth
    .contract(TruffleContractInstance._json.abi)
    .new.getData(...args, {
      data: TruffleContractInstance._json.bytecode
    });
  console.log("bytecode", bytecode);

  // estimate gas
  const estimatedGas = web3.toHex(
    await peth.estimateGas({
      data: bytecode,
      ...extra
    })
  );
  console.log("estimatedGas", estimatedGas);

  // construct pseudo transaction
  const rawTransaction = RLP.encode([
    Bytes.fromNumber(0), // nonce
    Bytes.fromNat(gasPrice), // gas price
    Bytes.fromNat(estimatedGas), // gas
    "0x", // to address
    Bytes.fromNumber(0), // value
    bytecode, // data
    Bytes.fromNumber(27), // v
    "0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798".toLowerCase(), // r
    "0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" // s
  ]);
  console.log("rawTransaction", rawTransaction);

  // recover signer
  const signer = Transaction.recover(rawTransaction);
  console.log("signer", signer);

  // calculate gas cost
  const gasCost = web3
    .toBigNumber(gasPrice)
    .mul(web3.toBigNumber(estimatedGas));
  // console.log("total gas cost", gasCost.toString());

  // send that money to signer
  await peth.sendTransaction({
    from: extra.from,
    to: signer,
    value: web3.toWei(1, "ether")
  });
  console.log("balance", (await peth.getBalance(signer)).toString());

  // deploy contract
  const txId = await peth.sendRawTransaction(rawTransaction);
  const { contractAddress: address } = await peth.getTransactionReceipt(txId);
  const code = await peth.getCode(address);
  console.log(code);
};

module.exports = {
  deployContract,
  deterministicallyDeploy
};
