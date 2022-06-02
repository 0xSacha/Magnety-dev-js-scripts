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


    it("should deploy vaultFactory", async function () {
        await ctx.deployContracts([
            { name: "vaultFactory", src: "VaultFactory", params: {} },
            { name: "saver", src: "Saver", params: {} },
        ])
        // expect(ctx.vaultFactory).not.to.be.undefined
        // expect(ctx.vaultFactory.address).not.to.be.undefined
        // expect(ctx.saver).not.to.be.undefined
        // expect(ctx.saver.address).not.to.be.undefined
        let vaultFactoryAddress = ctx.vaultFactory.address
        console.log(`vaultFactory addr: ${vaultFactoryAddress}`)
    });
    it("should deploy Accounts", async function () {
        await deployAccounts(ctx, ["alice"])
        // console.log("alice", ctx.alice.starknetContract._address)
        console.log("alice", ctx.alice.address)
    });

    it("should deploy dependencies", async function () {
        let vaultFactoryAddress = ctx.vaultFactory.address
        let saverAddress = ctx.saver.address
        const AliceAddress = ctx.alice.address
        await ctx.deployContracts([
            { name: "comptroller", src: "Comptroller", params: { _vaultFactory: vaultFactoryAddress, _saver: saverAddress } },
            { name: "feeManager", src: "FeeManager", params: { _vaultFactory: vaultFactoryAddress } },
            { name: "integrationManager", src: "IntegrationManager", params: { _vaultFactory: vaultFactoryAddress } },
            { name: "policyManager", src: "PolicyManager", params: { _vaultFactory: vaultFactoryAddress } },
            // { name: "pontisPriceFeedMixin", src: "PontisPriceFeedMixin", params: { _vaultFactory: vaultFactoryAddress } },
            // { name: "valueInterpretor", src: "ValueInterpretor", params: { _vaultFactory: vaultFactoryAddress } },
        ])
        // expect(ctx.comptroller).not.to.be.undefined
        // expect(ctx.comptroller.address).not.to.be.undefined
        // expect(ctx.feeManager).not.to.be.undefined
        // expect(ctx.feeManager.address).not.to.be.undefined
        // expect(ctx.integrationManager).not.to.be.undefined
        // expect(ctx.integrationManager.address).not.to.be.undefined
        // expect(ctx.policyManager).not.to.be.undefined
        // expect(ctx.policyManager.address).not.to.be.undefined
        // expect(ctx.mockPontis).not.to.be.undefined
        // expect(ctx.mockPontis.address).not.to.be.undefined
        // expect(ctx.btc).not.to.be.undefined
        // expect(ctx.btc.address).not.to.be.undefined
        // expect(ctx.eth).not.to.be.undefined
        // expect(ctx.eth.address).not.to.be.undefined
        // expect(ctx.valueInterpretor).not.to.be.undefined
        // expect(ctx.valueInterpretor.address).not.to.be.undefined
        // expect(ctx.pontisPriceFeedMixin).not.to.be.undefined
        // expect(ctx.pontisPriceFeedMixin.address).not.to.be.undefined
        // console.log(`comptroller addr: ${ctx.comptroller.address}`)
        // console.log(`feeManager addr: ${ctx.feeManager.address}`)
        // console.log(`integrationManager addr: ${ctx.integrationManager.address}`)
        // console.log(`policyManager addr: ${ctx.policyManager.address}`)
        // console.log(`btc addr: ${ctx.btc.address}`)
        // console.log(`eth addr: ${ctx.eth.address}`)
    });

    it("should initialize dependencies", async function () {
        let comptrollerAddress = ctx.comptroller.address
        let feeManagerAddress = ctx.feeManager.address
        let policyManagerAddress = ctx.policyManager.address
        let integrationManagerAddress = ctx.integrationManager.address
        let pontisPriceFeedMixinAddress = "0x075d5b80c222e259d8dc8ff4cc0c5a9814942f210b5b68ce5062a11b73b0a6e7"
        let valueInterpretorAddress = "0x046f1fada567408141c9da54f7ff684bf79e8a85f8ef6e8b78a0e67972125c02"
        let oracle = "0"
        console.log("111111111111111111")

        await ctx.execute("alice", "vaultFactory", "setComptroller", {
            _comptrolleur: comptrollerAddress
        })
        await ctx.execute("alice", "vaultFactory", "setFeeManager", {
            _feeManager: feeManagerAddress
        })
        await ctx.execute("alice", "vaultFactory", "setPolicyManager", {
            _policyManager: policyManagerAddress
        })
        await ctx.execute("alice", "vaultFactory", "setIntegrationManager", {
            _integrationManager: integrationManagerAddress
        })
        console.log("22222222222222222222")

        await ctx.execute("alice", "vaultFactory", "setOracle", {
            _oracle: oracle
        })
        await ctx.execute("alice", "vaultFactory", "setValueInterpretor", {
            _valueInterpretor: valueInterpretorAddress
        })
        console.log("3333333333333333333333")

        await ctx.execute("alice", "vaultFactory", "setPrimitivePriceFeed", {
            _primitivePriceFeed: pontisPriceFeedMixinAddress
        })

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
