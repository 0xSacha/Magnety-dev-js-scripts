import { expect } from "chai";
import { starknet } from "hardhat";
import { StarknetContract, StarknetContractFactory } from "hardhat/types/runtime";
import { TIMEOUT } from "./constants";
import { startListener } from "../scripts/event";
import { felthex, feltstr, addr, fromfelt, timer, felt, deployAccounts, deployContracts, getInitialContext } from "../scripts/util";
import { doesNotMatch, doesNotReject } from "assert";

// analyse event and do callBack

describe("fullTest", function () {
  this.timeout(TIMEOUT);
  let ctx: any = getInitialContext()
  console.log("ctx getted")

  it("should deploy dependencies", async function () {
    await ctx.deployContracts([
      // { name: "alphaRoadFinanceLP", src: "alphaRoadFinanceLP", params: {} },
      // { name: "alphaRoadFinanceToken", src: "alphaRoadFinanceToken", params: {} },
      { name: "comptroller", src: "Comptroller", params: { _vaultFactory: "0x0783e102c476819d520ce5a831f9c1ae8281e7fbe9b74838ece6880b97c63ab5", _saver: "0x0088eeb407649664a83ddfad83c88e272d7a2800343a61292ca9643fa736c0be" } },
    ])

  });



});