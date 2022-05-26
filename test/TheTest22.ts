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
        ])
        expect(ctx.vaultFactory).not.to.be.undefined
        expect(ctx.vaultFactory.address).not.to.be.undefined
        let vaultFactoryAddress = ctx.vaultFactory.address
        console.log(`vaultFactory addr: ${vaultFactoryAddress}`)
    });
    it("should deploy Accounts", async function () {
        await deployAccounts(ctx, ["alice", "bob", "carol", "dave", "amber", "kim", "shane"])
        // console.log("alice", ctx.alice.starknetContract._address)
        console.log("alice", ctx.alice.address)
    });

    it("should deploy dependencies", async function () {
        let vaultFactoryAddress = ctx.vaultFactory.address
        const AliceAddress = ctx.alice.address
        await ctx.deployContracts([
            { name: "integrationManager", src: "IntegrationManager", params: { _vaultFactory: vaultFactoryAddress } },
            { name: "btc", src: "ERC20", params: { name: felt("btc"), symbol: felt("btc"), decimals: 18, initial_supply: { low: 9000000000000000000, high: 0 }, recipient: AliceAddress, owner: AliceAddress, } },
            { name: "eth", src: "ERC20", params: { name: felt("eth"), symbol: felt("eth"), decimals: 18, initial_supply: { low: 5000000000000000000, high: 0 }, recipient: AliceAddress, owner: AliceAddress, } },
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
        let integrationManagerAddress = ctx.integrationManager.address
        let btcAddress = ctx.btc.address
        let ethAddress = ctx.eth.address
        let vaultFactoryAddress = ctx.vaultFactory.address

        await ctx.execute("alice", "vaultFactory", "setIntegrationManager", {
            _integrationManager: integrationManagerAddress
        })

        await ctx.execute("alice", "vaultFactory", "addGlobalAllowedAsset", {
            _assetList: [ethAddress, btcAddress]
        })

        const availableAsset = await ctx.integrationManager.call("getAvailableAssets", {})
        console.log(availableAsset)

        const availableIntegration = await ctx.integrationManager.call("getAvailableIntegrations", {})
        console.log(availableIntegration)

        await ctx.execute("alice", "vaultFactory", "addGlobalAllowedIntegration", {
            _integrationList: [{ contract: 900000000000, selector: 77777, integration: 678787 }, { contract: 376872854, selector: 5785857777, integration: 678787 }]
        })

        const availableIntegration2 = await ctx.integrationManager.call("getAvailableIntegrations", {})
        console.log(availableIntegration2)

    });

});
