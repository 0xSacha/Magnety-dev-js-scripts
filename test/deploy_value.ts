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
            { name: "valueInterpretor", src: "ValueInterpretor", params: { _vaultFactory: "0x07e16969f27d6d968043d3a7e5dd4739f4895f5be397fac0fc204504efb203b0" } },
        ])

    });



});
