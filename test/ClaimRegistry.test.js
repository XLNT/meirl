const { deterministicallyDeploy } = require("./util/deploy");
const expectEvent = require("./util/events");
const web3Utils = require("web3-utils");

const ClaimRegistry = artifacts.require("ClaimRegistry");

const MOCK_KEY = web3Utils.soliditySha3("test");
const MOCK_VALUE = web3.toHex("yeet");
const MOCK_URI = "https://example.com";
const NULL_URI = "";

const shouldBehaveLikeClaimRegistry = function([issuer, subject]) {
  describe("issue()", function() {
    it("should allow anyone to issue a claim", async function() {
      await expectEvent.inTransaction(
        this.registry.issue(subject, MOCK_KEY, MOCK_VALUE, MOCK_URI, {
          from: issuer
        }),
        "ClaimIssued",
        {
          issuer,
          subject,
          key: MOCK_KEY,
          value: MOCK_VALUE,
          uri: MOCK_URI
        }
      );
    });

    it("should allow anyone to issue a claim without a uri", async function() {
      await expectEvent.inTransaction(
        this.registry.issue(subject, MOCK_KEY, MOCK_VALUE, NULL_URI, {
          from: issuer
        }),
        "ClaimIssued",
        {
          issuer,
          subject,
          key: MOCK_KEY,
          value: MOCK_VALUE,
          uri: NULL_URI
        }
      );
    });
  });

  describe("registerURIFormat()", function() {
    it("allows anyone to register a uri fomat for themselves", async function() {
      await expectEvent.inTransaction(
        this.registry.registerIssuerURIFormat(MOCK_URI, { from: issuer }),
        "URIFormatRegistered",
        {
          issuer,
          uriFormat: MOCK_URI
        }
      );
    });
  });

  describe("revoke()", function() {
    it("allows anyone to revoke", async function() {
      const claimId = web3Utils.soliditySha3(
        issuer,
        subject,
        MOCK_KEY,
        MOCK_VALUE
      );
      await expectEvent.inTransaction(
        this.registry.revoke(claimId, { from: issuer }),
        "ClaimRevoked",
        {
          issuer,
          claimId
        }
      );
    });
  });
  describe("revokeBySubjectAndKey()", function() {
    it("allows anyone to revokeBySubjectAndKey", async function() {
      const claimId = web3Utils.soliditySha3(issuer, subject, MOCK_KEY);
      await expectEvent.inTransaction(
        this.registry.revokeBySubjectAndKey(claimId, { from: issuer }),
        "ClaimRevokedBySubjectAndKey",
        {
          issuer,
          claimId
        }
      );
    });
  });
  describe("revokeBySubject()", function() {
    it("allows anyone to revokeBySubject", async function() {
      const claimId = web3Utils.soliditySha3(issuer, subject);
      await expectEvent.inTransaction(
        this.registry.revokeBySubject(claimId, { from: issuer }),
        "ClaimRevokedBySubject",
        {
          issuer,
          claimId
        }
      );
    });
  });
};

contract("ClaimRegistry", function([_, deployer, ...accounts]) {
  context.only("normally deployed", function() {
    beforeEach(async function() {
      this.registry = await ClaimRegistry.new();
    });

    shouldBehaveLikeClaimRegistry(accounts);
  });

  context("deterministically deployed", function() {
    beforeEach(async function() {
      this.registry = await deterministicallyDeploy(
        ClaimRegistry,
        [],
        web3.toHex(web3.toWei(100, "gwei")),
        { from: deployer }
      );
    });

    shouldBehaveLikeClaimRegistry(accounts);
  });
});
