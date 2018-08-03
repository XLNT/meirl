const RLP = require('rlp')
const b = require('buidler')
const peth = b.pweb3.eth

const GREETING = 'Hello, buidler!'

// @TODO - if args provided, construct a delegate call to `target.initialize(...args)`
const proxyFor = (target, args) => `0x603160008181600b9039f3600080808080368092803773${target.replace('0x', '')}5af43d828181803e808314602f57f35bfd`

const contractAddress = (sender, nonce) => b.web3.utils.sha3(RLP.encode([ sender, nonce ])).substr(-40)

const AdminUpgradeabilityProxy = b.artifacts.require('AdminUpgradeabilityProxy')
const Greeter = b.artifacts.require('Greeter')

const estimateDeploy = async (artifact, args, admin) => {
  const Contract = b.web3.eth.contract(artifact._json.abi)
  const data = Contract.new.getData(...args, { data: artifact._json.bytecode })

  return peth.estimateGas({
    from: admin,
    data,
  })
}

const estimateContract = async (data, from) => peth.estimateGas({
  from,
  data,
})

const deployContract = async (data, from) => {
  const res = await peth.sendTransaction({ from, data })
  const receipt = await peth.getTransactionReceipt(res)

  return receipt.contractAddress
}

const getProxyFromChain = async (proxyFactories) => {
  let prevAddr

  for (let i = proxyFactories.length - 1; i > 0; i--) {
    prevAddr = await proxyFactories[i](prevAddr)
  }

  return prevAddr
}

const shouldBeGreeter = async (addr, anyone) => {
  const identityGreeter = Greeter.at(addr)
  await identityGreeter.setGreet(GREETING, { from: anyone })

  const gotGreeting = await identityGreeter.greet({ from: anyone })
  assert.equal(gotGreeting, GREETING)
}

contract('Identity', ([ _, admin, anyone ]) => {
  beforeEach(async function () {
    this.greeter = await Greeter.new()
  })

  it('should proxy -> impl', async function () {
    const finalAddress = await getProxyFromChain([
      async (addr) => deployContract(proxyFor(addr), admin),
      () => this.greeter.address,
    ])

    await shouldBeGreeter(finalAddress, anyone)
  })

  it('should be able to proxy -> admin -> impl', async function () {
    const finalAddress = await getProxyFromChain([
      async (addr) => deployContract(proxyFor(addr), admin),
      async (addr) => (await AdminUpgradeabilityProxy.new(addr, { from: admin })).address,
      () => this.greeter.address,
    ])

    await shouldBeGreeter(finalAddress, anyone)
  })

  it('should be able to admin -> proxy -> impl with proxy chain', async function () {
    const finalAddress = await getProxyFromChain([
      async (addr) => (await AdminUpgradeabilityProxy.new(addr, { from: admin })).address,
      async (addr) => deployContract(proxyFor(addr), admin),
      () => this.greeter.address,
    ])

    await shouldBeGreeter(finalAddress, anyone)
  })

  it('should be able to proxy -> proxy -> impl', async function () {
    const finalAddress = await getProxyFromChain([
      async (addr) => deployContract(proxyFor(addr), admin),
      async (addr) => deployContract(proxyFor(addr), admin),
      () => this.greeter.address,
    ])

    await shouldBeGreeter(finalAddress, anyone)
  })

  // this test is very confusing.
  it('should be able to proxy hella times', async function () {
    const finalAddress = await getProxyFromChain([
      async (addr) => deployContract(proxyFor(addr), admin),
      async (addr) => deployContract(proxyFor(addr), admin),
      // async (addr) => (await AdminUpgradeabilityProxy.new(addr, { from: admin })).address,
      async (addr) => deployContract(proxyFor(addr), admin),
      () => this.greeter.address,
    ])

    await shouldBeGreeter(finalAddress, anyone)
  })
})
