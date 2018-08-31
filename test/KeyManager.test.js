contract("KeyManager", function() {
  context("Management", function() {
    it("should not allow non-management keys to manage identity");
    it("should be able to add keys");
    it("should be able to remove keys");
  });

  context("Action", function() {
    it("should not allow non-action keys to send transactions");
    it("should allow an action key to send a generic call transaction");
    it(
      "should allow an action key to send a generic delegate call transaction"
    );
  });

  context("Claim", function() {
    it(
      "should not allow non-claim keys to send a transaction to the ClaimRegistry"
    );
    it("should allow claim keys to send a transaction to the ClaimRegistry");
  });

  context("Encryption", function() {
    it("should not allow non-encryption keys to encrypt data");
    it("should allow encryption keys to encrypt data");
  });

  context("Off Chain Authorization", function() {
    it(
      "should not allow non-off-chain-authorization keys to authorize the identity off-chain"
    );
    it(
      "should allow off-chain-authorization keys to authorize the identity off-chain"
    );
  });
});
