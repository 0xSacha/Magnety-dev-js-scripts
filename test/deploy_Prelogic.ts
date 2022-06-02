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
            { name: "alphaRoadLiquidty", src: "AlphaRoadLiquidty", params: { _IARFPoolFactory: "0x00373c71f077b96cbe7a57225cd503d29cadb0056ed741a058094234d82de2f9" } },
            { name: "alphaRoadSwap", src: "AlphaRoadSwap", params: {} },
        ])
    });
});
