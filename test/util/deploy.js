const pify = require("pify");
const peth = pify(web3.eth);

const deployContract = async (data, extra = {}) => {
  const res = await peth.sendTransaction({ ...extra, data });
  const receipt = await peth.getTransactionReceipt(res);

  return receipt.contractAddress;
};

module.exports = {
  deployContract
};
