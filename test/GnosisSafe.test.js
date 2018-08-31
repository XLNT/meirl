const { proxyFor } = require("./util/proxies");
const { deployContract } = require("./util/deploy");

const GnosisSafe = artifacts.require("GnosisSafe");

require("chai")
  .use(require("chai-bignumber")(web3.BigNumber))
  .should();

contract("GnosisSafe", function([
  _,
  deployer,
  authorized,
  offChainAuthorizer,
  encryptor,
  claimer
]) {
  context("by iteself", function() {
    beforeEach(async function() {
      this.safe = await GnosisSafe.new({ from: deployer });
      await this.safe.setup([authorized], 1, 0, 0, { from: deployer });
    });

    it("works", async function() {
      (await this.safe.NAME()).should.equal("Gnosis Safe"); // ??? Gnosis Safe ???
      (await this.safe.VERSION()).should.equal("0.0.1");
    });
  });

  context("as a proxy", function() {
    beforeEach(async function() {
      this.master = await GnosisSafe.new({ from: deployer });
      await this.master.setup([authorized], 1, 0, 0, { from: deployer });

      this.proxyAddress = await deployContract(proxyFor(this.master.address), {
        from: deployer
      });
      this.safe = await GnosisSafe.at(this.proxyAddress);
    });

    it("works", async function() {
      (await this.safe.NAME()).should.equal("Gnosis Safe"); // ??? Gnosis Safe ???
      (await this.safe.VERSION()).should.equal("0.0.1");
    });
  });
});
