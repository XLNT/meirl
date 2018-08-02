const RLP = require('rlp')
const b = require('buidler')
const peth = b.pweb3.eth

const GREETING = 'Hello, buidler!'

// @TODO - if args provided, construct a delegate call to `target.initialize(...args)`
const proxyFor = (target, args) => `0x603160008181600b9039f3600080808080368092803773${target.replace('0x', '')}5af43d828181803e808314602f57f35bfd`

const contractAddress = (sender, nonce) => b.web3.utils.sha3(RLP.encode([ sender, nonce ])).substr(-40)

const CustomAdminUpgradeabilityProxy = b.artifacts.require('CustomAdminUpgradeabilityProxy')
const AdminUpgradeabilityProxy = b.artifacts.require('AdminUpgradeabilityProxy')
const Greeter = b.artifacts.require('Greeter')

const estimateDeploy = async (artifact, args, owner) => {
  const Contract = b.web3.eth.contract(artifact._json.abi)
  const data = Contract.new.getData(...args, { data: artifact._json.bytecode })

  return peth.estimateGas({
    from: owner,
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

contract('Identity', ([ _, owner, anyone ]) => {
  beforeEach(async function () {
    this.greeter = await Greeter.new()
  })

  it('Should return the right greeting', async function () {
    await this.greeter.setGreet(GREETING)
    const gotGreeting = await this.greeter.greet()

    assert.equal(gotGreeting, GREETING)
  })

  describe('AdminUpgradeabilityProxy', function () {
    it('should work', async function () {
      const identityImplementation = await AdminUpgradeabilityProxy.new(this.greeter.address, { from: owner })

      const identityGreeter = Greeter.at(identityImplementation.address)
      await identityGreeter.setGreet(GREETING, { from: anyone })

      const gotGreeting = await identityGreeter.greet({ from: anyone })
      assert.equal(gotGreeting, GREETING)
    })

    it('should be able to proxy twice', async function () {
      const firstProxy = await CustomAdminUpgradeabilityProxy.new(this.greeter.address, { from: owner })
      const secondProxy = await AdminUpgradeabilityProxy.new(firstProxy.address, { from: owner })

      const identityGreeter = Greeter.at(secondProxy.address)
      await identityGreeter.setGreet(GREETING, { from: anyone })

      const gotGreeting = await identityGreeter.greet({ from: anyone })
      assert.equal(gotGreeting, GREETING)
    })
  })

  it('Identity', async function () {
    const data = proxyFor(this.greeter.address)

    console.log('proxy gas:', await estimateContract(data, owner))
    const contractAddress = await deployContract(data, owner)

    const identityGreeter = Greeter.at(contractAddress)
    await identityGreeter.setGreet(GREETING)

    const gotGreeting = await identityGreeter.greet()
    assert.equal(gotGreeting, GREETING)
  })

  it('should be able to proxy through proxy', async function () {
    const firstProxy = await AdminUpgradeabilityProxy.new(this.greeter.address, { from: owner })

    const data = proxyFor(firstProxy.address)
    const secondProxy = await deployContract(data, owner)

    const identityGreeter = Greeter.at(secondProxy)
    await identityGreeter.setGreet(GREETING, { from: anyone })

    const gotGreeting = await identityGreeter.greet({ from: anyone })
    assert.equal(gotGreeting, GREETING)
  })
})
