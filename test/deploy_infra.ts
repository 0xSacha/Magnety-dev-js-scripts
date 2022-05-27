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
        expect(ctx.vaultFactory).not.to.be.undefined
        expect(ctx.vaultFactory.address).not.to.be.undefined
        expect(ctx.saver).not.to.be.undefined
        expect(ctx.saver.address).not.to.be.undefined
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
            { name: "pontisPriceFeedMixin", src: "PontisPriceFeedMixin", params: { _vaultFactory: vaultFactoryAddress } },
            { name: "valueInterpretor", src: "ValueInterpretor", params: { _vaultFactory: vaultFactoryAddress } },
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
        let pontisPriceFeedMixinAddress = ctx.pontisPriceFeedMixin.address
        let valueInterpretorAddress = ctx.valueInterpretor.address


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
        await ctx.execute("alice", "vaultFactory", "setValueInterpretor", {
            _valueInterpretor: valueInterpretorAddress
        })
        await ctx.execute("alice", "vaultFactory", "setPrimitivePriceFeed", {
            _primitivePriceFeed: pontisPriceFeedMixinAddress
        })
    });

});
