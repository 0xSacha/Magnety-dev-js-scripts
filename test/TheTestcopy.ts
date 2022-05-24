import { expect } from "chai";
import { starknet } from "hardhat";
import { StarknetContract, StarknetContractFactory } from "hardhat/types/runtime";
import { TIMEOUT } from "./constants";
import { startListener } from "../scripts/event";
import { felthex, feltstr, addr, fromfelt, timer, felt, deployAccounts, deployContracts, getInitialContext } from "../scripts/util";

// analyse event and do callBack

describe("fullTest", function () {
    this.timeout(TIMEOUT);
    let ctx: any = getInitialContext()
    console.log("ctx getted")

    it("should deploy Accounts", async function () {
        await deployAccounts(ctx, ["alice", "bob", "carol", "dave"])
        console.log("alice", ctx.alice.address)

    });

    it("should deploy vaultFactory", async function () {
        await ctx.deployContracts([
            { name: "vaultFactory", src: "VaultFactory", params: {} },
        ])
        expect(ctx.vaultFactory).not.to.be.undefined
        expect(ctx.vaultFactory.address).not.to.be.undefined
        let vaultFactoryAddress = ctx.vaultFactory.address
        console.log(`vaultFactory addr: ${vaultFactoryAddress}`)
    });


    it("should deploy dependencies", async function () {
        let vaultFactoryAddress = ctx.vaultFactory.address
        const AliceAddress = ctx.alice.address
        await ctx.deployContracts([
            { name: "integrationManager", src: "IntegrationManager", params: { _vaultFactory: vaultFactoryAddress } },
            { name: "btc", src: "ERC20", params: { name: felt("btc"), symbol: felt("btc"), decimals: 18, initial_supply: { low: 9000000000000000000, high: 0 }, recipient: AliceAddress, owner: AliceAddress, } },
            { name: "eth", src: "ERC20", params: { name: felt("eth"), symbol: felt("eth"), decimals: 18, initial_supply: { low: 2000000000000000000, high: 0 }, recipient: AliceAddress, owner: AliceAddress, } },
        ])
        const integrationManagerAddress = ctx.integrationManager.address
        const ethAddress = ctx.btc.address
        const btcAddress = ctx.eth.address
        await ctx.execute("alice", "vaultFactory", "setIntegrationManager", {
            _integrationManager: integrationManagerAddress
        })
        await ctx.execute("alice", "vaultFactory", "addGlobalAllowedAsset", {
            _assetList: [ethAddress, btcAddress]
        })
        console.log("check asset available + approve available")
        const isAllowedAsseteth = await ctx.integrationManager.call("checkIsAssetAvailable", { _asset: ethAddress })
        console.log(isAllowedAsseteth)
        const isAllowedAssetbtc = await ctx.integrationManager.call("checkIsAssetAvailable", { _asset: btcAddress })
        console.log(isAllowedAssetbtc)
    });
    // it("should deploy dependencies", async function () {
    //     console.log("alice", ctx.alice.address)
    //     console.log("alice", felthex(ctx.alice.address))
    //     const AliceAddress = ctx.alice.address
    //     await ctx.deployContracts([
    //         { name: "btc", src: "ERC20", params: { name: felt("usdt"), symbol: felt("usdt"), decimals: 18, initial_supply: { low: 100000, high: 0 }, recipient: AliceAddress, owner: AliceAddress, } },
    //         { name: "eth", src: "ERC20", params: { name: felt("dai"), symbol: felt("dai"), decimals: 18, initial_supply: { low: 100000, high: 0 }, recipient: AliceAddress, owner: AliceAddress, } },
    //     ])

    //     expect(ctx.eth).not.to.be.undefined
    //     expect(ctx.eth.address).not.to.be.undefined
    //     console.log(`btc addr: ${ctx.btc.address}`)
    //     console.log(`eth addr: ${ctx.eth.address}`)
    //     const balanceAlice = await ctx.btc.call("balanceOf", { account: AliceAddress })
    //     console.log(balanceAlice)
    // });


    // it("test transfer asset", async () => {
    //     const AliceAddress = ctx.alice.address
    //     const balanceAlice = await ctx.btc.call("balanceOf", { AliceAddress })
    //     console.log(balanceAlice)
    //     // await ctx.btc.invoke("setFeeManager", { _feeManager: addr(ctx.fee_manager.address) })
    //     // const { res: fee_manager_addr } = await ctx.fund_deployer.call("getFeeManager", {})
    //     // console.log("fee_manager", addr(fee_manager_addr).toString())
    //     // expect(feltstr(fee_manager_addr)).to.be.equal(addr(ctx.fee_manager.address).toString())
    // })

    // it("Should add comptroller version to fund_deployer", async () => {
    //     await ctx.fund_deployer.invoke("add_comptroller_version", { comptroller: addr(ctx.comptroller_lib.address) })
    //     const { version, address } = await ctx.fund_deployer.call("get_latest_comptroller_version", {})
    //     expect(feltstr(version)).to.be.equal("1")
    //     expect(feltstr(address)).to.be.equal(feltstr(ctx.comptroller_lib.address))
    // })

    // it("Should create accounts", async () => {
    //     await ctx.deployAccounts(["alice", "bob", "carol", "dave"])
    //     expect(ctx.alice).not.to.be.undefined
    //     expect(ctx.bob).not.to.be.undefined
    //     expect(ctx.carol).not.to.be.undefined
    //     expect(ctx.dave).not.to.be.undefined
    //     console.log(ctx.alice.address)
    // })

    // it("should create vault", async () => {
    //     const _fundName = felt("vault0")
    //     const _fundSymbol = felt("vault0")
    //     const _deno = felt("usdt")
    //     console.log("alice", ctx.alice.address)
    // await ctx.execute("alice", "fund_deployer", "createNewFund", {
    //     _fundName, _fundSymbol, _denominationAsset: _deno
    // })

    //     // await timer(80000)
    //     // await timer(80000)

    //     for (let i = 0; i < 1000; i++) {
    //         await timer(1000)
    //         const { version, address } = await ctx.fund_deployer.call("get_latest_comptroller_version", {})

    //         // await ctx.fund_deployer.invoke("set_vault_comptroller", { vault: addr(ctx.alice.address), comptroller_address: address })

    //         let { comptroller } = await ctx.call("alice", "fund_deployer", "get_vault_comptroller", { vault: addr(ctx.alice.address) })
    //         console.log("comptroller", feltstr(comptroller))
    //         if (feltstr(comptroller) == "0")
    //             continue
    //         console.log("passed comptroller", feltstr(comptroller))
    //         expect(feltstr(comptroller)).not.to.be.undefined
    //         expect(feltstr(comptroller)).to.be.equal(feltstr(ctx.comptroller_lib.address))
    //         break
    //     }
    // })
});
