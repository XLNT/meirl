const pify = require("pify");
const peth = pify(web3.eth);

const AdminUpgradeabilityProxy = artifacts.require(
  "AdminUpgradeabilityProxyMock"
);
const Greeter = artifacts.require("Greeter");

require("chai")
  .use(require("chai-bignumber")(web3.BigNumber))
  .should();

const GREETING = "Hello, buidler!";
const proxyFor = target =>
  `0x603160008181600b9039f3600080808080368092803773${target.replace(
    "0x",
    ""
  )}5af43d828181803e808314602f57f35bfd`;

const deployContract = async (data, from) => {
  const res = await peth.sendTransaction({ from, data });
  const receipt = await peth.getTransactionReceipt(res);

  return receipt.contractAddress;
};

const getProxyFromChain = async proxyFactories => {
  let prevAddr;

  for (let i = proxyFactories.length - 1; i > 0; i--) {
    prevAddr = await proxyFactories[i](prevAddr);
  }

  return prevAddr;
};

const shouldBeGreeter = async (addr, anyone) => {
  const identityGreeter = Greeter.at(addr);
  await identityGreeter.setGreet(GREETING, { from: anyone });

  const gotGreeting = await identityGreeter.greet({ from: anyone });
  gotGreeting.should.eq(GREETING);
};

contract("Identity", ([_, admin, anyone]) => {
  beforeEach(async function() {
    this.greeter = await Greeter.new();
  });

  it("should proxy -> impl", async function() {
    const finalAddress = await getProxyFromChain([
      async addr => deployContract(proxyFor(addr), admin),
      () => this.greeter.address
    ]);

    await shouldBeGreeter(finalAddress, anyone);
  });

  it("should be able to proxy -> admin -> impl", async function() {
    const finalAddress = await getProxyFromChain([
      async addr => deployContract(proxyFor(addr), admin),
      async addr =>
        (await AdminUpgradeabilityProxy.new(addr, { from: admin })).address,
      () => this.greeter.address
    ]);

    await shouldBeGreeter(finalAddress, anyone);
  });

  it("should be able to admin -> proxy -> impl with proxy chain", async function() {
    const finalAddress = await getProxyFromChain([
      async addr =>
        (await AdminUpgradeabilityProxy.new(addr, { from: admin })).address,
      async addr => deployContract(proxyFor(addr), admin),
      () => this.greeter.address
    ]);

    await shouldBeGreeter(finalAddress, anyone);
  });

  it("should be able to proxy -> proxy -> impl", async function() {
    const finalAddress = await getProxyFromChain([
      async addr => deployContract(proxyFor(addr), admin),
      async addr => deployContract(proxyFor(addr), admin),
      () => this.greeter.address
    ]);

    await shouldBeGreeter(finalAddress, anyone);
  });

  // this test is very confusing.
  it("should be able to proxy hella times", async function() {
    const finalAddress = await getProxyFromChain([
      async addr => deployContract(proxyFor(addr), admin),
      async addr =>
        (await AdminUpgradeabilityProxy.new(addr, { from: admin })).address,
      async addr => deployContract(proxyFor(addr), admin),
      async addr => deployContract(proxyFor(addr), admin),
      () => this.greeter.address
    ]);

    await shouldBeGreeter(finalAddress, anyone);
  });
});
