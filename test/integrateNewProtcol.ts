import { expect } from "chai";
import { starknet } from "hardhat";
import { StarknetContract, StarknetContractFactory } from "hardhat/types/runtime";
import { TIMEOUT } from "./constants";
import { startListener } from "../scripts/event";
import { felthex, feltstr, addr, fromfelt, timer, felt, deployAccounts, deployContracts, getInitialContext, loadMainAccount } from "../scripts/util";
import { doesNotMatch, doesNotReject } from "assert";
import { getSelectorFromName } from 'starknet/dist/utils/hash';


// Oracle 
const PontisOracle = "0x013befe6eda920ce4af05a50a67bd808d67eee6ba47bb0892bef2d630eaf1bba"
const PontisKey = "ETH/BTC"

// Integration 

const ARFSwapControlleur = "0x04aec73f0611a9be0524e7ef21ab1679bdf9c97dc7d72614f15373d431226b6a"
const ARFPoolFactory = "0x00373c71f077b96cbe7a57225cd503d29cadb0056ed741a058094234d82de2f9"
// Token
const Eth = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"
const BTC = "0x072df4dc5b6c4df72e4288857317caf2ce9da166ab8719ab8306516a2fddfff7"
const ZKP = "0x07a6dde277913b4e30163974bf3d8ed263abb7c7700a18524f5edf38a13d39ec"
const TST = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"

// LP
const Eth_ZKP = "0x068f02f0573d85b5d54942eea4c1bf97c38ca0e3e34fe3c974d1a3feef6c33be"
const BTC_TST = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"
const ETH_TST = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"
const ETH_BTC = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"

const swap = getSelectorFromName("swap")

describe("Deploy and initialize infrastrcture", function () {
    this.timeout(TIMEOUT);
    let ctx: any = getInitialContext()
    console.log("ctx getted")

    it("should deploy Master Account", async function () {
        await loadMainAccount(ctx)
    });
    it("should Load vaultFactory", async function () {
        await ctx.deployContracts([
            { name: "vaultFactory", src: "VaultFactory", params: {} },
        ])
        expect(ctx.vaultFactory).not.to.be.undefined
        expect(ctx.vaultFactory.address).not.to.be.undefined
        let vaultFactoryAddress = ctx.vaultFactory.address
        console.log(`vaultFactory addr: ${vaultFactoryAddress}`)
    });


    it("Add global allowed Assets + ", async function () {

        // await ctx.execute("alice", "vaultFactory", "addGlobalAllowedAsset", {
        //     _assetList: ["0x072df4dc5b6c4df72e4288857317caf2ce9da166ab8719ab8306516a2fddfff7", "0x07a6dde277913b4e30163974bf3d8ed263abb7c7700a18524f5edf38a13d39ec", "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"
        //         , "0x07394cbe418daa16e42b87ba67372d4ab4a5df0b05c6e554d158458ce245bc10", "0x068f02f0573d85b5d54942eea4c1bf97c38ca0e3e34fe3c974d1a3feef6c33be", "0x06d0845eb49bcbef8c91f9717623b56331cc4205a5113bddef98ec40f050edc8",
        //         "0x0212040ea46c99455a30b62bfe9239f100271a198a0fdf0e86befc30e510e443", "0x061fdcf831f23d070b26a4fdc9d43c2fbba1928a529f51b5335cd7b738f97945"]
        // })
        // await ctx.execute("alice", "vaultFactory", "addGlobalAllowedIntegration", {
        //     _integrationList: [
        //         ["0x4aec73f0611a9be0524e7ef21ab1679bdf9c97dc7d72614f15373d431226b6a", "0x2c0f7bf2d6cf5304c29171bf493feb222fef84bdaf17805a6574b0c2e8bcc87", "0x06d5483321e825a2712a2862c1d8cb60d20c485e2cbf9277fa543f4c646312ba"],
        //         ["0x4aec73f0611a9be0524e7ef21ab1679bdf9c97dc7d72614f15373d431226b6a", "0x3f35dbce7a07ce455b128890d383c554afbc1b07cf7390a13e2d602a38c1a0a", "0x071022eeb1763628f03a0ffcfd0c7b6eff3cfb3a964b064691e4828d8264c03a"],
        //         ["0x4aec73f0611a9be0524e7ef21ab1679bdf9c97dc7d72614f15373d431226b6a", "0x147fd8f7d12de6da66feedc6d64a11bd371e5471ee1018f11f9072ede67a0fa", "0"],
        //     ]
        // })

    });

});
