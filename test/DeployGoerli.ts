import { expect } from "chai";
import { starknet } from "hardhat";
import { StarknetContract, StarknetContractFactory } from "hardhat/types/runtime";
import { TIMEOUT } from "./constants";
import { startListener } from "../scripts/event";
import { felthex, feltstr, addr, fromfelt, timer, felt, deployAccounts, deployContracts, getInitialContext, loadMainAccount } from "../scripts/util";
import { doesNotMatch, doesNotReject } from "assert";
import { getSelectorFromName } from 'starknet/dist/utils/hash';

const removeLiquidity = "0x147fd8f7d12de6da66feedc6d64a11bd371e5471ee1018f11f9072ede67a0fa"
const swapExactTokensForTokens = "0x2c0f7bf2d6cf5304c29171bf493feb222fef84bdaf17805a6574b0c2e8bcc87"
const addLiquidity = "0x3f35dbce7a07ce455b128890d383c554afbc1b07cf7390a13e2d602a38c1a0a"

// Oracle 
const PontisOracle = "0x013befe6eda920ce4af05a50a67bd808d67eee6ba47bb0892bef2d630eaf1bba"
const PontisKey = ""

// Integration 
const ARFSwapControlleur = "0x04aec73f0611a9be0524e7ef21ab1679bdf9c97dc7d72614f15373d431226b6a"
const ARFPoolFactory = "0x00373c71f077b96cbe7a57225cd503d29cadb0056ed741a058094234d82de2f9"
// Token
// Token
const Eth = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"
const EthUsdKey = "28556963469423460"
const BTC = "0x072df4dc5b6c4df72e4288857317caf2ce9da166ab8719ab8306516a2fddfff7"
const ZKP = "0x07a6dde277913b4e30163974bf3d8ed263abb7c7700a18524f5edf38a13d39ec"
const TST = "0x07394cbe418daa16e42b87ba67372d4ab4a5df0b05c6e554d158458ce245bc10"

// LP
const Eth_ZKP = "0x068f02f0573d85b5d54942eea4c1bf97c38ca0e3e34fe3c974d1a3feef6c33be"
const BTC_TST = "0x06d0845eb49bcbef8c91f9717623b56331cc4205a5113bddef98ec40f050edc8"
const ETH_TST = "0x0212040ea46c99455a30b62bfe9239f100271a198a0fdf0e86befc30e510e443"
const ETH_BTC = "0x061fdcf831f23d070b26a4fdc9d43c2fbba1928a529f51b5335cd7b738f97945"

const ARFLiquidity = "0x07b6036caf1baefaace9f5cd72194e1a3f7f0ed6e883cf8fefe68a1e968579a1"
const ARFSwap = "0x03325e38ced6b1aed89da2ee72b267fe4b9b8ebc6ba4ba220ce25a7fae64f460"


describe("Deploy and initialize infrastrcture", function () {
    this.timeout(TIMEOUT);
    let ctx: any = getInitialContext()
    console.log("ctx getted")

    it("should deploy Master Account", async function () {
        await loadMainAccount(ctx)
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
        await ctx.deployContracts([
            // Controller
            { name: "comptroller", src: "Comptroller", params: { _vaultFactory: vaultFactoryAddress } },

            // Extensions
            { name: "feeManager", src: "FeeManager", params: { _vaultFactory: vaultFactoryAddress } },
            { name: "integrationManager", src: "IntegrationManager", params: { _vaultFactory: vaultFactoryAddress } },
            { name: "policyManager", src: "PolicyManager", params: { _vaultFactory: vaultFactoryAddress } },

            // Value interpretor + derivative/externalPosition pricefeed
            { name: "valueInterpretor", src: "ValueInterpretor", params: { _vaultFactory: vaultFactoryAddress, _ethAddress: Eth } },
            { name: "pontisPriceFeedMixin", src: "PontisPriceFeedMixin", params: { _vaultFactory: vaultFactoryAddress } },
            { name: "alphaRoadFinanceLP", src: "AlphaRoadFinanceLP", params: { _vaultFactory: vaultFactoryAddress } },
            { name: "alphaRoadFinanceToken", src: "AlphaRoadFinanceToken", params: { _vaultFactory: vaultFactoryAddress } },

            //Pre logic contracts
            { name: "alphaRoadLiquidty", src: "AlphaRoadLiquidty", params: { _IARFPoolFactory: ARFPoolFactory } },
            { name: "alphaRoadSwap", src: "AlphaRoadSwap", params: {} },
        ])
        expect(ctx.comptroller).not.to.be.undefined
        expect(ctx.comptroller.address).not.to.be.undefined


        expect(ctx.feeManager).not.to.be.undefined
        expect(ctx.feeManager.address).not.to.be.undefined
        expect(ctx.integrationManager).not.to.be.undefined
        expect(ctx.integrationManager.address).not.to.be.undefined
        expect(ctx.policyManager).not.to.be.undefined
        expect(ctx.policyManager.address).not.to.be.undefined

        expect(ctx.valueInterpretor).not.to.be.undefined
        expect(ctx.valueInterpretor.address).not.to.be.undefined
        expect(ctx.pontisPriceFeedMixin).not.to.be.undefined
        expect(ctx.pontisPriceFeedMixin.address).not.to.be.undefined
        expect(ctx.alphaRoadFinanceLP).not.to.be.undefined
        expect(ctx.alphaRoadFinanceLP.address).not.to.be.undefined
        expect(ctx.alphaRoadFinanceToken).not.to.be.undefined
        expect(ctx.alphaRoadFinanceToken.address).not.to.be.undefined

        expect(ctx.alphaRoadLiquidty).not.to.be.undefined
        expect(ctx.alphaRoadLiquidty.address).not.to.be.undefined
        expect(ctx.alphaRoadSwap).not.to.be.undefined
        expect(ctx.alphaRoadSwap.address).not.to.be.undefined

        console.log(` comptroller address : ${ctx.comptroller.address}`)
        console.log(` FM address : ${ctx.feeManager.address}`)
        console.log(` IM address : ${ctx.integrationManager.address}`)
        console.log(` PM address : ${ctx.policyManager.address}`)
        console.log(` VI address : ${ctx.valueInterpretor.address}`)
        console.log(` PPFM address : ${ctx.pontisPriceFeedMixin.address}`)
        console.log(` ARFLP address : ${ctx.alphaRoadFinanceLP.address}`)
        console.log(` ARFToken address : ${ctx.alphaRoadFinanceToken.address}`)
        console.log(` ARFLiquidity address : ${ctx.alphaRoadLiquidty.address}`)
        console.log(` ARFSwap address : ${ctx.alphaRoadSwap.address}`)

        console.log()
    });

    // it("should deploy Accounts", async function () {
    //     await deployAccounts(ctx, ["alice"])
    //     // console.log("alice", ctx.alice.starknetContract._address)
    //     console.log("alice", "bob", "marley", "lucas", ctx.alice.address)
    // });

    it("should initialize dependencies", async function () {
        // await ctx.execute("master", "vaultFactory", "claimOwnership", {})

        // await ctx.execute("master", "vaultFactory", "setComptroller", {
        //     _comptrolleur: ctx.comptroller.address
        // })
        // await ctx.execute("master", "vaultFactory", "setOracle", {
        //     _oracle: PontisOracle
        // })
        // //Extensions
        // await ctx.execute("master", "vaultFactory", "setFeeManager", {
        //     _feeManager: ctx.feeManager.address
        // })
        // await ctx.execute("master", "vaultFactory", "setPolicyManager", {
        //     _policyManager: ctx.policyManager.address
        // })
        // await ctx.execute("master", "vaultFactory", "setIntegrationManager", {
        //     _integrationManager: ctx.integrationManager.address
        // })
        // //value Interpretor
        // await ctx.execute("master", "vaultFactory", "setValueInterpretor", {
        //     _valueInterpretor: ctx.valueInterpretor.address
        // })
        // await ctx.execute("master", "vaultFactory", "setPrimitivePriceFeed", {
        //     _primitivePriceFeed: ctx.pontisPriceFeedMixin.address
        // })

        // await ctx.execute("master", "vaultFactory", "setStackingVault", {
        //     _stackingVault: ctx.bob.address
        // })
        // await ctx.execute("master", "vaultFactory", "setDaoTreasury", {
        //     _daoTreasury: ctx.pontisPriceFeedMixin.address
        // })

    });
    it("Add global allowed Assets + ", async function () {
        await ctx.execute("master", "vaultFactory", "addGlobalAllowedAsset", {
            _assetList: [BTC_TST, ETH_BTC, BTC, ETH_TST, Eth, Eth_ZKP, ZKP, TST]
        })

        await ctx.execute("master", "vaultFactory", "addGlobalAllowedIntegration", {
            _integrationList: [{ contract: ARFSwapControlleur, selector: swapExactTokensForTokens, integration: ARFSwap },
            { contract: ARFSwapControlleur, selector: addLiquidity, integration: ARFLiquidity },
            { contract: ARFSwapControlleur, selector: removeLiquidity, integration: "0" }]
        })

        await ctx.execute("master", "pontisPriceFeedMixin", "addPrimitive", {
            _asset: Eth, _key: felt("eth/usd")
        })


        await ctx.execute("master", "valueInterpretor", "addDerivative", {
            _derivative: Eth_ZKP, _priceFeed: ctx.alphaRoadFinanceLP.address
        }).then(() => console.log("donnnnnnnnee"))

        await ctx.execute("master", "valueInterpretor", "addDerivative", {
            _derivative: ETH_BTC, _priceFeed: ctx.alphaRoadFinanceLP.address
        })
        await ctx.execute("master", "valueInterpretor", "addDerivative", {
            _derivative: ETH_TST, _priceFeed: ctx.alphaRoadFinanceLP.address
        })
        console.log("step2")
        await ctx.execute("master", "valueInterpretor", "addDerivative", {
            _derivative: BTC_TST, _priceFeed: ctx.alphaRoadFinanceLP.address
        })



        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: BTC, _priceFeed: ctx.alphaRoadFinanceToken.address
        // })
        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: ZKP, _priceFeed: ctx.alphaRoadFinanceToken.address
        // })
        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: TST, _priceFeed: ctx.alphaRoadFinanceToken.address
        // })

        // await ctx.execute("master", "alphaRoadFinanceToken", "setIARFSwapController", {
        //     _IARFSwapController: ARFSwapControlleur,
        // })
    });

    it("should initialize dependencies", async function () {


        await ctx.execute("master", "alphaRoadFinanceToken", "addPoolAddress", {
            _derivative: BTC, _pool: ETH_BTC
        })

        await ctx.execute("master", "alphaRoadFinanceToken", "addPoolAddress", {
            _derivative: TST, _pool: ETH_TST
        })

        await ctx.execute("master", "alphaRoadFinanceToken", "addPoolAddress", {
            _derivative: ZKP, _pool: Eth_ZKP
        })

        await ctx.execute("master", "valueInterpretor", "addDerivative", {
            _derivative: BTC, _priceFeed: ctx.alphaRoadFinanceToken.address
        })
        await ctx.execute("master", "valueInterpretor", "addDerivative", {
            _derivative: ZKP, _priceFeed: ctx.alphaRoadFinanceToken.address
        })
        await ctx.execute("master", "valueInterpretor", "addDerivative", {
            _derivative: TST, _priceFeed: ctx.alphaRoadFinanceToken.address
        })

        await ctx.execute("master", "alphaRoadFinanceToken", "setIARFSwapController", {
            _IARFSwapController: ARFSwapControlleur,
        })

        await ctx.execute("master", "alphaRoadFinanceLP", "setIARFSwapController", {
            _IARFSwapController: ARFSwapControlleur,
        })

    });
    // it("should deploy vault, initialize it and activate it ", async function () {
    //     let vaultFactoryAddress = ctx.vaultFactory.address
    //     let comptrollerAddress = ctx.comptroller.address
    //     let btcAddress = ctx.btc.address
    //     let ethAddress = ctx.eth.address
    //     console.log("create vault")
    //     await ctx.deployContracts([
    //         { name: "vault", src: "Vault", params: { _vaultFactory: vaultFactoryAddress, _comptroller: comptrollerAddress } },
    //     ])
    //     let vaultAddress = ctx.vault.address
    //     console.log("initialize vault")
    //     await ctx.execute("alice", "vaultFactory", "initializeFund", {
    //         _vault: ctx.vault.address, _fundName: felt("myamazingfund"), _fundSymbol: felt("myFund"), _denominationAsset: ethAddress, _positionLimitAmount: { low: 250n, high: 0 }, _feeConfig: [10, 10, 10, 10], _assetList: [btcAddress, ethAddress], _integration: [], _minAmount: { low: 1000000000000000n, high: 0 }, _maxAmount: { low: 1000000000000000000000n, high: 0 }, _timelock: 0, _isPublic: 1
    //     })
    //     // console.log("check initalization fee manager")
    //     // const timestamp = await ctx.feeManager.call("getClaimedTimestamp", { vault: vaultAddress })
    //     // console.log(timestamp)
    //     // const EF = await ctx.feeManager.call("getEntranceFee", { vault: vaultAddress })
    //     // console.log(EF)
    //     // const EXF = await ctx.feeManager.call("getExitFee", { vault: vaultAddress })
    //     // console.log(EXF)
    //     // const PF = await ctx.feeManager.call("getPerformanceFee", { vault: vaultAddress })
    //     // console.log(PF)
    //     // const MF = await ctx.feeManager.call("getManagementFee", { vault: vaultAddress })
    //     // console.log(MF)
    //     // console.log("check initalization policy manager")
    //     // const MMA = await ctx.policyManager.call("getMaxminAmount", { _vault: vaultAddress })
    //     // console.log(MMA)
    //     // const TL = await ctx.policyManager.call("getTimelock", { _vault: vaultAddress })
    //     // console.log(TL)
    //     // const PU = await ctx.policyManager.call("checkIsPublic", { _vault: vaultAddress })
    //     // console.log(PU)
    //     // const ALT = await ctx.policyManager.call("checkIsAllowedTrackedAsset", { _vault: vaultAddress, _asset: ethAddress })
    //     // console.log(ALT)
    //     // const ALT2 = await ctx.policyManager.call("checkIsAllowedTrackedAsset", { _vault: vaultAddress, _asset: btcAddress })
    //     // console.log(ALT2)
    //     // const ALINT = await ctx.policyManager.call("checkIsAllowedIntegration", { _vault: vaultAddress, _contract: ethAddress, _selector: 949021990203918389843157787496164629863144228991510976554585288817234167820n })
    //     // console.log(ALINT)
    //     // const ALINT2 = await ctx.policyManager.call("checkIsAllowedIntegration", { _vault: vaultAddress, _contract: btcAddress, _selector: 949021990203918389843157787496164629863144228991510976554585288817234167820n })
    //     // console.log(ALINT2)

    //     const comptroller_address = ctx.comptroller.address
    //     await ctx.execute("alice", "eth", "approve", {
    //         spender: comptroller_address, amount: { low: 2000000000000000000n, high: 0 }
    //     })
    //     await ctx.execute("alice", "comptroller", "activateVault", {
    //         _vault: vaultAddress, _asset: ethAddress, _amount: { low: 2000000000000000000n, high: 0 }
    //     })
    //     console.log("check save ")
    //     // const vaultAmount = await ctx.comptroller.call("getVaultAmount", {})
    //     // console.log(vaultAmount)

    //     // const vaultAmountofcaller = await ctx.comptroller.call("getVaultAmountFromCaller", { _caller: ctx.alice.address })
    //     // console.log(vaultAmountofcaller)

    //     // const vaultfromalice = await ctx.comptroller.call("getVaultAddressFromCallerAndId", { _caller: ctx.alice.address, _vaultId: 0 })
    //     // console.log(vaultfromalice)

    //     // const vaultfrom0 = await ctx.comptroller.call("getVaultAddressFromId", { _vaultId: 0 })
    //     // console.log(vaultfrom0)

    //     // console.log("check share price & gav")
    //     // const shareprice = await ctx.comptroller.call("getSharePrice", { _vault: vaultAddress })
    //     // console.log(shareprice)

    //     // const gav = await ctx.comptroller.call("calc_gav", { _vault: vaultAddress })
    //     // console.log(gav)


    //     // console.log("add track asset btc")
    //     // await ctx.execute("alice", "comptroller", "addTrackedAsset", {
    //     //     _vaultId: 0, _asset: btcAddress
    //     // })

    //     // console.log("transfer 1 btc to vault")
    //     // await ctx.execute("alice", "btc", "transfer", {
    //     //     recipient: vaultAddress, amount: { low: 1000000000000000000n, high: 0 }
    //     // })

    //     // console.log("check share price & gav")
    //     // const shareprice2 = await ctx.comptroller.call("getSharePrice", { _vault: vaultAddress })
    //     // console.log(shareprice2)

    //     // const gav2 = await ctx.comptroller.call("calc_gav", { _vault: vaultAddress })
    //     // console.log(gav2)
    // });

    // // it("transfer eth to bob and bob buy shares", async () => {
    // //     const BobAddress = ctx.bob.address
    // //     const CarolAddress = ctx.carol.address
    // //     const DaveAddress = ctx.dave.address
    // //     const AliceAddress = ctx.alice.address
    // //     let vaultAddress = ctx.vault.address
    // //     let ethAddress = ctx.eth.address

    // //     console.log("set stacking vault & dao treasury")

    // //     await ctx.execute("alice", "vaultFactory", "setDaoTreasury", {
    // //         _daoTreasury: CarolAddress
    // //     })

    // //     await ctx.execute("alice", "vaultFactory", "setStackingVault", {
    // //         _stackingVault: DaveAddress
    // //     })

    // //     console.log("transfer 1 eth to bob")

    // //     await ctx.execute("alice", "eth", "transfer", {
    // //         recipient: BobAddress, amount: { low: 1000000000000000000n, high: 0 }
    // //     })
    // //     console.log("chekc before buy parameters")

    // //     console.log("check share price & gav")
    // //     const shareprice2 = await ctx.comptroller.call("getSharePrice", { _vault: vaultAddress })
    // //     console.log(shareprice2)

    // //     const gav2 = await ctx.comptroller.call("calc_gav", { _vault: vaultAddress })
    // //     console.log(gav2)

    // //     const shareAmount = await ctx.vault.call("getSharesBalance", { tokenId: { low: 0, high: 0 } })
    // //     console.log(shareAmount)

    // //     const bobybalance = await ctx.eth.call("balanceOf", { account: BobAddress })
    // //     console.log(bobybalance)
    // //     const Alicebalance = await ctx.eth.call("balanceOf", { account: AliceAddress })
    // //     console.log(Alicebalance)
    // //     const daotreasuryamount = await ctx.eth.call("balanceOf", { account: CarolAddress })
    // //     console.log(daotreasuryamount)
    // //     const stackingVaultAmount = await ctx.eth.call("balanceOf", { account: DaveAddress })
    // //     console.log(stackingVaultAmount)


    // //     const comptroller_address = ctx.comptroller.address
    // //     await ctx.execute("bob", "eth", "approve", {
    // //         spender: comptroller_address, amount: { low: 500000000000000000n, high: 0 }
    // //     })

    // //     console.log("bob buy shares with 0.5 eth")
    // //     await ctx.execute("bob", "comptroller", "buyShare", {
    // //         _vault: vaultAddress, _asset: ethAddress, _amount: { low: 500000000000000000n, high: 0 }
    // //     })

    // //     console.log("check share price, should not change if everything correct")
    // //     const shareprice3 = await ctx.comptroller.call("getSharePrice", { _vault: vaultAddress })
    // //     console.log(shareprice3)

    // //     const gav3 = await ctx.comptroller.call("calc_gav", { _vault: vaultAddress })
    // //     console.log(gav3)

    // //     const shareAmount2 = await ctx.vault.call("getSharesBalance", { tokenId: { low: 1, high: 0 } })
    // //     console.log(shareAmount2)

    // //     console.log("chekc after buy parameters")
    // //     const bobybalance2 = await ctx.eth.call("balanceOf", { account: BobAddress })
    // //     console.log(bobybalance2)
    // //     const Alicebalance2 = await ctx.eth.call("balanceOf", { account: AliceAddress })
    // //     console.log(Alicebalance2)
    // //     const daotreasuryamount2 = await ctx.eth.call("balanceOf", { account: CarolAddress })
    // //     console.log(daotreasuryamount2)
    // //     const stackingVaultAmount2 = await ctx.eth.call("balanceOf", { account: DaveAddress })
    // //     console.log(stackingVaultAmount2)
    // // })

    // // it("bob sell shares 50%btc 50%eth", async () => {
    // //     const BobAddress = ctx.bob.address
    // //     const CarolAddress = ctx.carol.address
    // //     const DaveAddress = ctx.dave.address
    // //     const AliceAddress = ctx.alice.address
    // //     let vaultAddress = ctx.vault.address
    // //     let ethAddress = ctx.eth.address
    // //     let btcAddress = ctx.btc.address

    // //     console.log("chekc before sell parameters")
    // //     const bobybalance = await ctx.eth.call("balanceOf", { account: BobAddress })
    // //     console.log(bobybalance)
    // //     const Alicebalance = await ctx.eth.call("balanceOf", { account: AliceAddress })
    // //     console.log(Alicebalance)
    // //     const daotreasuryamount = await ctx.eth.call("balanceOf", { account: CarolAddress })
    // //     console.log(daotreasuryamount)
    // //     const stackingVaultAmount = await ctx.eth.call("balanceOf", { account: DaveAddress })
    // //     console.log(stackingVaultAmount)

    // //     console.log("bobshareamount:")
    // //     const shareAmount = await ctx.vault.call("getSharesBalance", { tokenId: { low: 1, high: 0 } })
    // //     console.log(shareAmount)


    // //     console.log("bob sell 200  shares")
    // //     await ctx.execute("bob", "comptroller", "sell_share", {
    // //         _vault: vaultAddress, token_id: { low: 1, high: 0 }, share_amount: { low: 200, high: 0 }, assets: [ethAddress, btcAddress], percents: [50, 50]
    // //     })

    // //     console.log("check share price, should not change if everything correct")
    // //     const shareprice3 = await ctx.comptroller.call("getSharePrice", { _vault: vaultAddress })
    // //     console.log(shareprice3)

    // //     const gav3 = await ctx.comptroller.call("calc_gav", { _vault: vaultAddress })
    // //     console.log(gav3)



    // //     console.log("chekc after buy parameters")
    // //     console.log("bob balance eth")
    // //     const bobybalance2 = await ctx.eth.call("balanceOf", { account: BobAddress })
    // //     console.log(bobybalance2)
    // //     console.log("bob balance btc")
    // //     const bobybalance3 = await ctx.btc.call("balanceOf", { account: BobAddress })
    // //     console.log(bobybalance3)
    // //     const Alicebalance2 = await ctx.eth.call("balanceOf", { account: AliceAddress })
    // //     console.log(Alicebalance2)
    // //     const daotreasuryamount2 = await ctx.eth.call("balanceOf", { account: CarolAddress })
    // //     console.log(daotreasuryamount2)
    // //     const stackingVaultAmount2 = await ctx.eth.call("balanceOf", { account: DaveAddress })
    // //     console.log(stackingVaultAmount2)

    // //     // claim management fee test complicated since we need to wait at least 1 day

    // // })

    // it("execute call ", async () => {
    //     const BobAddress = ctx.bob.address
    //     let ethAddress = ctx.eth.address
    //     let vaultAddress = ctx.vault.address

    //     console.log("alice execute approve call")
    //     await ctx.execute("alice", "comptroller", "executeCall", {
    //         _vaultId: 0, _contract: ethAddress, _selector: 949021990203918389843157787496164629863144228991510976554585288817234167820n, _callData: [BobAddress, 500, 0]
    //     })

    //     console.log("check if bob can spend 500 eth from the vault")
    //     const currentAllowance = await ctx.eth.call("allowance", { owner: vaultAddress, spender: BobAddress })
    //     console.log(currentAllowance)
    // })
});
