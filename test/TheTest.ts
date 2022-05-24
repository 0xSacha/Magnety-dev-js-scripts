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
            { name: "comptroller", src: "Comptroller", params: { _vaultFactory: vaultFactoryAddress } },
            { name: "feeManager", src: "FeeManager", params: { _vaultFactory: vaultFactoryAddress } },
            { name: "integrationManager", src: "IntegrationManager", params: { _vaultFactory: vaultFactoryAddress } },
            { name: "policyManager", src: "PolicyManager", params: { _vaultFactory: vaultFactoryAddress } },
            { name: "pontisPriceFeedMixin", src: "PontisPriceFeedMixin", params: { _vaultFactory: vaultFactoryAddress } },
            { name: "valueInterpretor", src: "ValueInterpretor", params: { _vaultFactory: vaultFactoryAddress } },
            { name: "mockPontis", src: "MockPontis", params: {} },
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
        let comptrollerAddress = ctx.comptroller.address
        let feeManagerAddress = ctx.feeManager.address
        let policyManagerAddress = ctx.policyManager.address
        let mockPontisAddress = ctx.mockPontis.address
        let integrationManagerAddress = ctx.integrationManager.address
        let pontisPriceFeedMixinAddress = ctx.pontisPriceFeedMixin.address
        let valueInterpretorAddress = ctx.valueInterpretor.address

        let btcAddress = ctx.btc.address
        let ethAddress = ctx.eth.address

        await ctx.execute("alice", "vaultFactory", "setComptroller", {
            _comptrolleur: comptrollerAddress
        })
        await ctx.execute("alice", "vaultFactory", "setOracle", {
            _oracle: mockPontisAddress
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

        console.log("set value price feed btc usd")
        await ctx.execute("alice", "mockPontis", "set_value", {
            key: felt("btc/usd"), value: 30000000000000000000000n
        })
        console.log("set value price feed eth usd")
        await ctx.execute("alice", "mockPontis", "set_value", {
            key: felt("eth/usd"), value: 2000000000000000000000n
        })

        await ctx.execute("alice", "pontisPriceFeedMixin", "addPrimitive", {
            _asset: ethAddress, _key: felt("eth/usd")
        })

        await ctx.execute("alice", "pontisPriceFeedMixin", "addPrimitive", {
            _asset: btcAddress, _key: felt("btc/usd")
        })

        await ctx.execute("alice", "vaultFactory", "addGlobalAllowedAsset", {
            _assetList: [ethAddress, btcAddress]
        })

        // console.log("check if primitive is working")
        // const btctoeth = await ctx.pontisPriceFeedMixin.call("calcAssetValueBmToDeno", { _baseAsset: btcAddress, _amount: { low: 1000000000000000000n, high: 0 }, _denominationAsset: ethAddress, })
        // console.log(btctoeth)

        // console.log("check asset available + approve available")
        // const isAllowedAsseteth = await ctx.integrationManager.call("checkIsAssetAvailable", { _asset: ethAddress })
        // console.log(isAllowedAsseteth)
        // const isAllowedAssetbtc = await ctx.integrationManager.call("checkIsAssetAvailable", { _asset: btcAddress })
        // console.log(isAllowedAssetbtc)
        // const isAllowedIntegrationeth = await ctx.integrationManager.call("checkIsIntegrationAvailable", { _contract: ethAddress, _selector: 949021990203918389843157787496164629863144228991510976554585288817234167820n })
        // console.log(isAllowedIntegrationeth)
        // const isAllowedIntegrationbtc = await ctx.integrationManager.call("checkIsIntegrationAvailable", { _contract: btcAddress, _selector: 949021990203918389843157787496164629863144228991510976554585288817234167820n })
        // console.log(isAllowedIntegrationbtc)

    });
    it("should deploy vault, initialize it and activate it ", async function () {
        let vaultFactoryAddress = ctx.vaultFactory.address
        let comptrollerAddress = ctx.comptroller.address
        let btcAddress = ctx.btc.address
        let ethAddress = ctx.eth.address
        console.log("create vault")
        await ctx.deployContracts([
            { name: "vault", src: "Vault", params: { _vaultFactory: vaultFactoryAddress, _comptroller: comptrollerAddress } },
        ])
        let vaultAddress = ctx.vault.address
        console.log("initialize vault")
        await ctx.execute("alice", "vaultFactory", "initializeFund", {
            _vault: ctx.vault.address, _fundName: felt("myamazingfund"), _fundSymbol: felt("myFund"), _denominationAsset: ethAddress, _positionLimitAmount: { low: 250n, high: 0 }, _feeConfig: [10, 10, 10, 10], _assetList: [btcAddress, ethAddress], _integration: [], _minAmount: { low: 1000000000000000n, high: 0 }, _maxAmount: { low: 1000000000000000000000n, high: 0 }, _timelock: 0, _isPublic: 1
        })
        // console.log("check initalization fee manager")
        // const timestamp = await ctx.feeManager.call("getClaimedTimestamp", { vault: vaultAddress })
        // console.log(timestamp)
        // const EF = await ctx.feeManager.call("getEntranceFee", { vault: vaultAddress })
        // console.log(EF)
        // const EXF = await ctx.feeManager.call("getExitFee", { vault: vaultAddress })
        // console.log(EXF)
        // const PF = await ctx.feeManager.call("getPerformanceFee", { vault: vaultAddress })
        // console.log(PF)
        // const MF = await ctx.feeManager.call("getManagementFee", { vault: vaultAddress })
        // console.log(MF)
        // console.log("check initalization policy manager")
        // const MMA = await ctx.policyManager.call("getMaxminAmount", { _vault: vaultAddress })
        // console.log(MMA)
        // const TL = await ctx.policyManager.call("getTimelock", { _vault: vaultAddress })
        // console.log(TL)
        // const PU = await ctx.policyManager.call("checkIsPublic", { _vault: vaultAddress })
        // console.log(PU)
        // const ALT = await ctx.policyManager.call("checkIsAllowedTrackedAsset", { _vault: vaultAddress, _asset: ethAddress })
        // console.log(ALT)
        // const ALT2 = await ctx.policyManager.call("checkIsAllowedTrackedAsset", { _vault: vaultAddress, _asset: btcAddress })
        // console.log(ALT2)
        // const ALINT = await ctx.policyManager.call("checkIsAllowedIntegration", { _vault: vaultAddress, _contract: ethAddress, _selector: 949021990203918389843157787496164629863144228991510976554585288817234167820n })
        // console.log(ALINT)
        // const ALINT2 = await ctx.policyManager.call("checkIsAllowedIntegration", { _vault: vaultAddress, _contract: btcAddress, _selector: 949021990203918389843157787496164629863144228991510976554585288817234167820n })
        // console.log(ALINT2)

        const comptroller_address = ctx.comptroller.address
        await ctx.execute("alice", "eth", "approve", {
            spender: comptroller_address, amount: { low: 2000000000000000000n, high: 0 }
        })
        await ctx.execute("alice", "comptroller", "activateVault", {
            _vault: vaultAddress, _asset: ethAddress, _amount: { low: 2000000000000000000n, high: 0 }
        })
        console.log("check save ")
        // const vaultAmount = await ctx.comptroller.call("getVaultAmount", {})
        // console.log(vaultAmount)

        // const vaultAmountofcaller = await ctx.comptroller.call("getVaultAmountFromCaller", { _caller: ctx.alice.address })
        // console.log(vaultAmountofcaller)

        // const vaultfromalice = await ctx.comptroller.call("getVaultAddressFromCallerAndId", { _caller: ctx.alice.address, _vaultId: 0 })
        // console.log(vaultfromalice)

        // const vaultfrom0 = await ctx.comptroller.call("getVaultAddressFromId", { _vaultId: 0 })
        // console.log(vaultfrom0)

        // console.log("check share price & gav")
        // const shareprice = await ctx.comptroller.call("getSharePrice", { _vault: vaultAddress })
        // console.log(shareprice)

        // const gav = await ctx.comptroller.call("calc_gav", { _vault: vaultAddress })
        // console.log(gav)


        // console.log("add track asset btc")
        // await ctx.execute("alice", "comptroller", "addTrackedAsset", {
        //     _vaultId: 0, _asset: btcAddress
        // })

        // console.log("transfer 1 btc to vault")
        // await ctx.execute("alice", "btc", "transfer", {
        //     recipient: vaultAddress, amount: { low: 1000000000000000000n, high: 0 }
        // })

        // console.log("check share price & gav")
        // const shareprice2 = await ctx.comptroller.call("getSharePrice", { _vault: vaultAddress })
        // console.log(shareprice2)

        // const gav2 = await ctx.comptroller.call("calc_gav", { _vault: vaultAddress })
        // console.log(gav2)
    });

    // it("transfer eth to bob and bob buy shares", async () => {
    //     const BobAddress = ctx.bob.address
    //     const CarolAddress = ctx.carol.address
    //     const DaveAddress = ctx.dave.address
    //     const AliceAddress = ctx.alice.address
    //     let vaultAddress = ctx.vault.address
    //     let ethAddress = ctx.eth.address

    //     console.log("set stacking vault & dao treasury")

    //     await ctx.execute("alice", "vaultFactory", "setDaoTreasury", {
    //         _daoTreasury: CarolAddress
    //     })

    //     await ctx.execute("alice", "vaultFactory", "setStackingVault", {
    //         _stackingVault: DaveAddress
    //     })

    //     console.log("transfer 1 eth to bob")

    //     await ctx.execute("alice", "eth", "transfer", {
    //         recipient: BobAddress, amount: { low: 1000000000000000000n, high: 0 }
    //     })
    //     console.log("chekc before buy parameters")

    //     console.log("check share price & gav")
    //     const shareprice2 = await ctx.comptroller.call("getSharePrice", { _vault: vaultAddress })
    //     console.log(shareprice2)

    //     const gav2 = await ctx.comptroller.call("calc_gav", { _vault: vaultAddress })
    //     console.log(gav2)

    //     const shareAmount = await ctx.vault.call("getSharesBalance", { tokenId: { low: 0, high: 0 } })
    //     console.log(shareAmount)

    //     const bobybalance = await ctx.eth.call("balanceOf", { account: BobAddress })
    //     console.log(bobybalance)
    //     const Alicebalance = await ctx.eth.call("balanceOf", { account: AliceAddress })
    //     console.log(Alicebalance)
    //     const daotreasuryamount = await ctx.eth.call("balanceOf", { account: CarolAddress })
    //     console.log(daotreasuryamount)
    //     const stackingVaultAmount = await ctx.eth.call("balanceOf", { account: DaveAddress })
    //     console.log(stackingVaultAmount)


    //     const comptroller_address = ctx.comptroller.address
    //     await ctx.execute("bob", "eth", "approve", {
    //         spender: comptroller_address, amount: { low: 500000000000000000n, high: 0 }
    //     })

    //     console.log("bob buy shares with 0.5 eth")
    //     await ctx.execute("bob", "comptroller", "buyShare", {
    //         _vault: vaultAddress, _asset: ethAddress, _amount: { low: 500000000000000000n, high: 0 }
    //     })

    //     console.log("check share price, should not change if everything correct")
    //     const shareprice3 = await ctx.comptroller.call("getSharePrice", { _vault: vaultAddress })
    //     console.log(shareprice3)

    //     const gav3 = await ctx.comptroller.call("calc_gav", { _vault: vaultAddress })
    //     console.log(gav3)

    //     const shareAmount2 = await ctx.vault.call("getSharesBalance", { tokenId: { low: 1, high: 0 } })
    //     console.log(shareAmount2)

    //     console.log("chekc after buy parameters")
    //     const bobybalance2 = await ctx.eth.call("balanceOf", { account: BobAddress })
    //     console.log(bobybalance2)
    //     const Alicebalance2 = await ctx.eth.call("balanceOf", { account: AliceAddress })
    //     console.log(Alicebalance2)
    //     const daotreasuryamount2 = await ctx.eth.call("balanceOf", { account: CarolAddress })
    //     console.log(daotreasuryamount2)
    //     const stackingVaultAmount2 = await ctx.eth.call("balanceOf", { account: DaveAddress })
    //     console.log(stackingVaultAmount2)
    // })

    // it("bob sell shares 50%btc 50%eth", async () => {
    //     const BobAddress = ctx.bob.address
    //     const CarolAddress = ctx.carol.address
    //     const DaveAddress = ctx.dave.address
    //     const AliceAddress = ctx.alice.address
    //     let vaultAddress = ctx.vault.address
    //     let ethAddress = ctx.eth.address
    //     let btcAddress = ctx.btc.address

    //     console.log("chekc before sell parameters")
    //     const bobybalance = await ctx.eth.call("balanceOf", { account: BobAddress })
    //     console.log(bobybalance)
    //     const Alicebalance = await ctx.eth.call("balanceOf", { account: AliceAddress })
    //     console.log(Alicebalance)
    //     const daotreasuryamount = await ctx.eth.call("balanceOf", { account: CarolAddress })
    //     console.log(daotreasuryamount)
    //     const stackingVaultAmount = await ctx.eth.call("balanceOf", { account: DaveAddress })
    //     console.log(stackingVaultAmount)

    //     console.log("bobshareamount:")
    //     const shareAmount = await ctx.vault.call("getSharesBalance", { tokenId: { low: 1, high: 0 } })
    //     console.log(shareAmount)


    //     console.log("bob sell 200  shares")
    //     await ctx.execute("bob", "comptroller", "sell_share", {
    //         _vault: vaultAddress, token_id: { low: 1, high: 0 }, share_amount: { low: 200, high: 0 }, assets: [ethAddress, btcAddress], percents: [50, 50]
    //     })

    //     console.log("check share price, should not change if everything correct")
    //     const shareprice3 = await ctx.comptroller.call("getSharePrice", { _vault: vaultAddress })
    //     console.log(shareprice3)

    //     const gav3 = await ctx.comptroller.call("calc_gav", { _vault: vaultAddress })
    //     console.log(gav3)



    //     console.log("chekc after buy parameters")
    //     console.log("bob balance eth")
    //     const bobybalance2 = await ctx.eth.call("balanceOf", { account: BobAddress })
    //     console.log(bobybalance2)
    //     console.log("bob balance btc")
    //     const bobybalance3 = await ctx.btc.call("balanceOf", { account: BobAddress })
    //     console.log(bobybalance3)
    //     const Alicebalance2 = await ctx.eth.call("balanceOf", { account: AliceAddress })
    //     console.log(Alicebalance2)
    //     const daotreasuryamount2 = await ctx.eth.call("balanceOf", { account: CarolAddress })
    //     console.log(daotreasuryamount2)
    //     const stackingVaultAmount2 = await ctx.eth.call("balanceOf", { account: DaveAddress })
    //     console.log(stackingVaultAmount2)

    //     // claim management fee test complicated since we need to wait at least 1 day

    // })

    it("execute call ", async () => {
        const BobAddress = ctx.bob.address
        let ethAddress = ctx.eth.address
        let vaultAddress = ctx.vault.address

        console.log("alice execute approve call")
        await ctx.execute("alice", "comptroller", "executeCall", {
            _vaultId: 0, _contract: ethAddress, _selector: 949021990203918389843157787496164629863144228991510976554585288817234167820n, _callData: [BobAddress, 500, 0]
        })

        console.log("check if bob can spend 500 eth from the vault")
        const currentAllowance = await ctx.eth.call("allowance", { owner: vaultAddress, spender: BobAddress })
        console.log(currentAllowance)
    })
});
