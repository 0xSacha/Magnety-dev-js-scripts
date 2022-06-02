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
            { name: "pontisPriceFeedMixin", src: "PontisPriceFeedMixin", params: { _vaultFactory: "3564458069355986954948628938682469354523466428687567186937053835835907113904" } },
        ])

    });



});
