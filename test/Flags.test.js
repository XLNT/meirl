const times = require("lodash/times");
const b = require("buidler");
const BN = require("bn.js");
const toBN = require("number-to-bn");

const FlagsMock = b.artifacts.require("FlagsMock");

const MAX_FLAGS = 64;
const ALL_FLAGS = times(64, i => toBN(1).ushln(i));
const NULL_FIELD = toBN(0);

const makeFlagSet = flags =>
  flags.reduce((memo, flag) => memo.or(flag), toBN(0));

const FULL_FIELD = makeFlagSet(ALL_FLAGS);
// given a string bits, convert it to a hexadeciaml number of length 16 (which === 32 bytes)
const toBytes8 = num => `0x${num.toString(16, 16)}`;
const toBits = num => num.toString(2, MAX_FLAGS);

require("chai")
  .use(require("chai-bignumber")(b.web3.BigNumber))
  .should();

contract("Flags", ([]) => {
  beforeEach(async function() {
    this.mock = await FlagsMock.new(toBytes8(NULL_FIELD));
  });

  describe("makeFlagSet", function() {
    beforeEach(async function() {
      this.flagA = ALL_FLAGS[4];
      this.flagB = ALL_FLAGS[60];
      // ^ two random flags
      this.newFlag = await this.mock.makeFlagSet([
        toBytes8(this.flagA),
        toBytes8(this.flagB)
      ]);
    });

    it("the compound flag has flag A", function() {
      toBN(this.newFlag)
        .and(this.flagA)
        .gt(0)
        .should.equal(true);
    });

    it("the compound flag has flag B", function() {
      toBN(this.newFlag)
        .and(this.flagB)
        .gt(0)
        .should.equal(true);
    });

    it("the compound flag doesn't have anything else", async function() {
      this.newFlag.should.equal(toBytes8(this.flagA.or(this.flagB)));
    });
  });

  context("default field", function() {
    for (const flag of ALL_FLAGS) {
      it(`should not have flag ${toBits(flag)}`, async function() {
        (await this.mock.hasFlag(toBytes8(flag))).should.equal(false);
      });
    }
  });

  describe("addFlag", function() {
    for (const flag of ALL_FLAGS) {
      it(`should add single flag ${toBits(flag)}`, async function() {
        await this.mock.addFlag(toBytes8(flag));
        (await this.mock.getField()).should.equal(toBytes8(flag));
      });
    }
  });

  describe("removeFlag", function() {
    beforeEach(async function() {
      this.mock = await FlagsMock.new(toBytes8(FULL_FIELD));
    });
    for (const flag of ALL_FLAGS) {
      it(`should remove single flag ${toBits(flag)}`, async function() {
        await this.mock.removeFlag(toBytes8(flag));
        (await this.mock.hasFlag(toBytes8(flag))).should.equal(false);
      });
    }
  });

  context("with multiple flags via addFlag", function() {
    it("should be able to add multiple flags", async function() {
      const flags = [ALL_FLAGS[2], ALL_FLAGS[3], ALL_FLAGS[60], ALL_FLAGS[7]];
      for (const flag of flags) {
        await this.mock.addFlag(toBytes8(flag));
      }
      (await this.mock.getField()).should.equal(toBytes8(makeFlagSet(flags)));
    });

    it("should be able to add some flags and remove some flags", async function() {
      const addFlags = [
        ALL_FLAGS[2],
        ALL_FLAGS[3],
        ALL_FLAGS[60],
        ALL_FLAGS[7]
      ];
      const removeFlags = [
        ALL_FLAGS[2],
        ALL_FLAGS[7],
        ALL_FLAGS[8],
        ALL_FLAGS[10]
      ];

      for (const flag of addFlags) {
        await this.mock.addFlag(toBytes8(flag));
      }

      for (const flag of removeFlags) {
        await this.mock.removeFlag(toBytes8(flag));
      }

      // should just be 3 and 60
      (await this.mock.getField()).should.equal(
        toBytes8(makeFlagSet([ALL_FLAGS[3], ALL_FLAGS[60]]))
      );
    });
  });
});
