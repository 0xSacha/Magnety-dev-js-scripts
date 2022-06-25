import { expect } from "chai";
import { starknet } from "hardhat";
import { StarknetContract, StarknetContractFactory } from "hardhat/types/runtime";
import { TIMEOUT } from "./constants";
import { startListener } from "../scripts/event";
import { felthex, feltstr, addr, fromfelt, timer, felt, deployAccounts, deployContracts, getInitialContext, loadMainAccount, loadMainAccount2 } from "../scripts/util";
import { doesNotMatch, doesNotReject } from "assert";
import { getSelectorFromName } from 'starknet/dist/utils/hash';


// Oracle 
const PontisOracle = "0x013befe6eda920ce4af05a50a67bd808d67eee6ba47bb0892bef2d630eaf1bba"
const PontisKey = ""

const ARFSwapControlleur = "0x04aec73f0611a9be0524e7ef21ab1679bdf9c97dc7d72614f15373d431226b6a"
const ARFPoolFactory = "0x00373c71f077b96cbe7a57225cd503d29cadb0056ed741a058094234d82de2f9"
const removeLiquidity = "0x147fd8f7d12de6da66feedc6d64a11bd371e5471ee1018f11f9072ede67a0fa"
const swapExactTokensForTokens = "0x2c0f7bf2d6cf5304c29171bf493feb222fef84bdaf17805a6574b0c2e8bcc87"
const addLiquidity = "0x3f35dbce7a07ce455b128890d383c554afbc1b07cf7390a13e2d602a38c1a0a"

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

const VF = "0x02bd1f8da1f976747cb0a671cec5157fb6f3f2285642e6673049ddecff8c231c"
const comptroller = "0x025bc7963aa2c95f1934074d7d096028bd611c3af15fcefd8aa0d2cba038cfda"
const FM = "0x057c840744601d320ef4f59e49cb76c9a64667b6183a043ac0355c853bc4e6b2"
const IM = "0x06e513b8ccb09c36b2441a391e9baab07a563532e8afdc0dce1f5bbb0672a648"
const PM = "0x006938a189544ec2d4110d2bd8e6b556e8adb9acc6859937891214f73789b8de"
const VI = "0x06a5d5708016115dd908e9c8123f190c0327715fa233357b670e7ef080301870"
const PPFM = "0x07cd501b3087cb8055a3ae1224380c2ad4015b2e4465339659867394d73dc799"
const ARFLP = "0x059eeffdbbed9fa4f87ce5baebca7e1e07ba17d5a1065450a6299b1875701557"
const ARFToken = "0x01a096a429b9b871da44976ef73c7638f061f146b4f16bba2d683e6e8ce52b68"
const ARFLiquidity = "0x04bfee1c089173805175f75437c2543a3bad49926d1c5dcfd5683b2759bf7692"
const ARFSwap = "0x06d12ce4c0a9266b78e00a11c76597cf48caea36a57ae421ed38a0890496ae72"


describe("Deploy and initialize infrastrcture", function () {
    this.timeout(TIMEOUT);
    let ctx: any = getInitialContext()
    console.log("ctx getted")

    it("should deploy Master Account", async function () {
        await loadMainAccount(ctx)
        console.log(ctx.master.account)
    });
    it("should load contracts", async function () {

        await ctx.loadContracts([
            { name: "vaultFactory", src: "VaultFactory", address: VF },
            { name: "comptroller", src: "Comptroller", address: comptroller },
            { name: "feeManager", src: "FeeManager", address: FM },
            { name: "integrationManager", src: "IntegrationManager", address: IM },
            { name: "policyManager", src: "PolicyManager", address: PM },
            { name: "valueInterpretor", src: "ValueInterpretor", address: VI },
            { name: "pontisPriceFeedMixin", src: "PontisPriceFeedMixin", address: PPFM },
            { name: "alphaRoadFinanceLP", src: "AlphaRoadFinanceLP", address: ARFLP },
            { name: "alphaRoadFinanceToken", src: "AlphaRoadFinanceToken", address: ARFToken },
            { name: "alphaRoadLiquidty", src: "AlphaRoadLiquidty", address: ARFLiquidity },
            { name: "alphaRoadSwap", src: "AlphaRoadSwap", address: ARFSwap },
            { name: "eth", src: "ERC20", address: Eth },

        ])
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
        console.log(` ETh address : ${ctx.eth.address}`)
    });



    it("should initialize dependencies", async function () {
        console.log("master balancer")
        const masterBalance = await ctx.eth.call("balanceOf", { account: ctx.master.address })
        console.log(masterBalance)


        await ctx.execute("master", "vaultFactory", "setStackingVault", {
            _stackingVault: "0x3acdb97d5fc69eeb39ba3517754372c88ccdcc8563d7c49636fde0b0a8f93da"
        })
        // await ctx.execute("master", "vaultFactory", "setDaoTreasury", {
        //     _daoTreasury: "0x048f24b4Dd688cd9F6f2a9c47bc7185BAf34e1530215d05A4A7C4c761BC41E56"
        // })
        // await ctx.execute("master", "alphaRoadFinanceToken", "addPoolAddress", {
        //     _derivative: BTC, _pool: ETH_BTC
        // })

        // await ctx.execute("master", "alphaRoadFinanceToken", "addPoolAddress", {
        //     _derivative: TST, _pool: ETH_TST
        // })

        // await ctx.execute("master", "alphaRoadFinanceToken", "addPoolAddress", {
        //     _derivative: ZKP, _pool: Eth_ZKP
        // })

        // await ctx.execute("master", "vaultFactory", "addGlobalAllowedIntegration", {
        //     _integrationList: [{ contract: ARFSwapControlleur, selector: swapExactTokensForTokens, integration: ARFSwap },
        //     { contract: ARFSwapControlleur, selector: addLiquidity, integration: ARFLiquidity },
        //     { contract: ARFSwapControlleur, selector: removeLiquidity, integration: "0" }]
        // })

        // await ctx.execute("master", "eth", "approve", {
        //     spender: comptroller, amount: { low: 100000000000000, high: 0 }
        // })


        // await ctx.execute("master", "comptroller", "buyShare", {
        //     _vault: "0x7e8b9e881747b536350237cf969f396bbba5034ea0a8350695d17050a5d76fd", _amount: { low: 1000000000000, high: 0 }
        // })



        // await ctx.execute("master", "vaultFactory", "setComptroller", {
        //     _comptrolleur: ctx.comptroller.address
        // })

        // await ctx.deployContracts([
        //     { name: "valueInterpretor", src: "ValueInterpretor", params: { _vaultFactory: VF, _ethAddress: Eth } },
        // ])

        // await ctx.execute("master", "vaultFactory", "setValueInterpretor", {
        //     _valueInterpretor: ctx.valueInterpretor.address
        // })

        // await ctx.execute("master", "pontisPriceFeedMixin", "addPrimitive", {
        //     _asset: Eth, _key: felt("eth/usd")
        // })

        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: Eth_ZKP, _priceFeed: ctx.alphaRoadFinanceLP.address
        // }).then(() => console.log("donnnnnnnnee"))

        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: ETH_BTC, _priceFeed: ctx.alphaRoadFinanceLP.address
        // })
        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: ETH_TST, _priceFeed: ctx.alphaRoadFinanceLP.address
        // })
        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: BTC_TST, _priceFeed: ctx.alphaRoadFinanceLP.address
        // })

        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: BTC, _priceFeed: ctx.alphaRoadFinanceToken.address
        // })
        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: ZKP, _priceFeed: ctx.alphaRoadFinanceToken.address
        // })
        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: TST, _priceFeed: ctx.alphaRoadFinanceToken.address
        // })



        // await ctx.execute("master", "vaultFactory", "addGlobalAllowedAsset", {
        //     _assetList: [BTC_TST, ETH_BTC, BTC, ETH_TST, Eth, Eth_ZKP, ZKP, TST]
        // })

        // await ctx.execute("master", "vaultFactory", "addGlobalAllowedIntegration", {
        //     _integrationList: [{ contract: ARFSwapControlleur, selector: swapExactTokensForTokens, integration: ARFSwap },
        //     { contract: ARFSwapControlleur, selector: addLiquidity, integration: ARFLiquidity },
        //     { contract: ARFSwapControlleur, selector: removeLiquidity, integration: "0" }]
        // })


        // await ctx.execute("master", "vaultFactory", "setComptroller", {
        //     _comptrolleur: ctx.comptroller.address
        // })

        // await ctx.execute("master", "eth", "approve", {
        //     spender: VF, amount: { low: 1000000000000000n, high: 0 }
        // })


        // await ctx.execute("master", "vaultFactory", "initializeFund", {
        //     _vault: ctx.vault.address, _fundName: felt("myamazingfund"), _fundSymbol: felt("FND"), _denominationAsset: Eth, _positionLimitAmount: { low: 250n, high: 0 }, _amount: { low: 1000000000000000, high: 0 }, _shareAmount: { low: 10000000000000000000n, high: 0 }, _feeConfig: [0, 0, 10, 10], _assetList: [Eth, BTC, ZKP, TST, Eth_ZKP, ETH_TST, ETH_BTC], _externalPositionList: [], _integration: [{ contract: ARFSwapControlleur, selector: swapExactTokensForTokens, integration: ARFSwap },
        //     { contract: ARFSwapControlleur, selector: addLiquidity, integration: ARFLiquidity },
        //     { contract: ARFSwapControlleur, selector: removeLiquidity, integration: "0" }], _minAmount: { low: 1000000000000000n, high: 0 }, _maxAmount: { low: 1000000000000000000000n, high: 0 }, _timelock: 150, _isPublic: 1
        // })



        // await ctx.execute("master", "comptroller", "addTrackedAsset", {
        //     _vault: "0x037b05ebd4b1bc1d3a0b8e07cf3fadd8709f184a9e17970ad56a6850235cc27b", _asset: "0x072df4dc5b6c4df72e4288857317caf2ce9da166ab8719ab8306516a2fddfff7"
        // })

        // await ctx.execute("master", "comptroller", "executeCall", {
        //     _vault: "0x037b05ebd4b1bc1d3a0b8e07cf3fadd8709f184a9e17970ad56a6850235cc27b", _contract: "0x04aec73f0611a9be0524e7ef21ab1679bdf9c97dc7d72614f15373d431226b6a", _selector: "0x2c0f7bf2d6cf5304c29171bf493feb222fef84bdaf17805a6574b0c2e8bcc87", _callData: ["0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7", "0x072df4dc5b6c4df72e4288857317caf2ce9da166ab8719ab8306516a2fddfff7", "1000000000", "0", "0", "0"]
        // })


        //allowed account for initialization
        // console.log("claiming ownership")
        // await ctx.execute("master", "vaultFactory", "claimOwnership", {})
        // console.log("done")
        // await ctx.execute("master", "comptroller", "setComptroller", {
        //     _comptrolleur: ctx.comptroller.address
        // })
        // await ctx.execute("master", "vaultFactory", "setOracle", {
        //     _oracle: PontisOracle
        // })
        //Extensions
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
        //     _stackingVault: "0x3b65de05321b92d3f6fc1e45ec54bde2754be65b3916d53c28641850dde2bce"
        // })
        // await ctx.execute("master", "vaultFactory", "setDaoTreasury", {
        //     _daoTreasury: "0x048f24b4Dd688cd9F6f2a9c47bc7185BAf34e1530215d05A4A7C4c761BC41E56"
        // })

    });

    it("should add pricefeed", async function () {
        console.log(felt("eth/usd"))
        console.log(EthUsdKey)

        // await ctx.execute("master", "vaultFactory", "addGlobalAllowedAsset", {
        //     _assetList: [BTC_TST, ETH_BTC, BTC, ETH_TST, Eth, Eth_ZKP, ZKP, TST]
        // })




        // await ctx.execute("master", "pontisPriceFeedMixin", "addPrimitive", {
        //     _asset: Eth, _key: felt("eth/usd")
        // })

        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: Eth_ZKP, _priceFeed: ctx.alphaRoadFinanceLP.address
        // }).then(() => console.log("donnnnnnnnee"))

        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: ETH_BTC, _priceFeed: ctx.alphaRoadFinanceLP.address
        // })
        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: ETH_TST, _priceFeed: ctx.alphaRoadFinanceLP.address
        // })
        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: BTC_TST, _priceFeed: ctx.alphaRoadFinanceLP.address
        // })


        // await ctx.execute("master", "alphaRoadFinanceToken", "addPoolAddress", {
        //     _derivative: BTC, _pool: ETH_BTC
        // })

        // await ctx.execute("master", "alphaRoadFinanceToken", "addPoolAddress", {
        //     _derivative: TST, _pool: ETH_TST
        // })

        // await ctx.execute("master", "alphaRoadFinanceToken", "addPoolAddress", {
        //     _derivative: ZKP, _pool: Eth_ZKP
        // })


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

        // await ctx.execute("master", "alphaRoadFinanceLP", "setIARFSwapController", {
        //     _IARFSwapController: ARFSwapControlleur,
        // })

        // await ctx.execute("master", "pontisPriceFeedMixin", "addPrimitive", {
        //     _asset: Eth, _key: felt("eth/usd")
        // })

        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: Eth_ZKP, _priceFeed: ARFLP
        // }).then(() => console.log("donnnnnnnnee"))

        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: ETH_BTC, _priceFeed: ARFLP
        // })
        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: ETH_TST, _priceFeed: ARFLP
        // })
        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: BTC_TST, _priceFeed: ARFLP
        // })


        // await ctx.execute("master", "alphaRoadFinanceToken", "addPoolAddress", {
        //     _derivative: BTC, _pool: ETH_BTC
        // })

        // await ctx.execute("master", "alphaRoadFinanceToken", "addPoolAddress", {
        //     _derivative: TST, _pool: ETH_TST
        // })

        // await ctx.execute("master", "alphaRoadFinanceToken", "addPoolAddress", {
        //     _derivative: ZKP, _pool: Eth_ZKP
        // })


        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: BTC, _priceFeed: ARFToken
        // })
        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: ZKP, _priceFeed: ARFToken
        // })
        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: TST, _priceFeed: ARFToken
        // })

        // await ctx.execute("master", "alphaRoadFinanceToken", "setIARFSwapController", {
        //     _IARFSwapController: ARFSwapControlleur,
        // })

        // await ctx.execute("master", "alphaRoadFinanceLP", "setIARFSwapController", {
        //     _IARFSwapController: ARFSwapControlleur,
        // })
    });

    it("Add global allowed Assets + Integration", async function () {

        // await ctx.execute("master", "vaultFactory", "addGlobalAllowedAsset", {
        //     _assetList: [BTC_TST, ETH_BTC, BTC, ETH_TST, Eth, Eth_ZKP, ZKP, TST]
        // })

        // await ctx.execute("master", "vaultFactory", "addGlobalAllowedIntegration", {
        //     _integrationList: [{ contract: ARFSwapControlleur, selector: swapExactTokensForTokens, integration: ARFSwap },
        //     { contract: ARFSwapControlleur, selector: addLiquidity, integration: ARFLiquidity },
        //     { contract: ARFSwapControlleur, selector: removeLiquidity, integration: "0" }]
        // })
        // console.log("donnnnnnne")
    });

    // ARFSwapControlleur, addLiquidity, ARFLiquidity, ARFSwapControlleur, removeLiquidity, "0"
    it("should deploy fund & initialize it", async function () {





        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: Eth_ZKP, _priceFeed: ctx.alphaRoadFinanceLP.address
        // }).then(() => console.log("donnnnnnnnee"))

        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: ETH_BTC, _priceFeed: ctx.alphaRoadFinanceLP.address
        // })
        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: ETH_TST, _priceFeed: ctx.alphaRoadFinanceLP.address
        // })
        // await ctx.execute("master", "valueInterpretor", "addDerivative", {
        //     _derivative: BTC_TST, _priceFeed: ctx.alphaRoadFinanceLP.address
        // })


        // await ctx.execute("master", "alphaRoadFinanceToken", "addPoolAddress", {
        //     _derivative: BTC, _pool: ETH_BTC
        // })

        // await ctx.execute("master", "alphaRoadFinanceToken", "addPoolAddress", {
        //     _derivative: TST, _pool: ETH_TST
        // })


        // await ctx.execute("master", "alphaRoadFinanceToken", "addPoolAddress", {
        //     _derivative: ZKP, _pool: Eth_ZKP
        // })


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
        // await ctx.deployContracts([
        //     { name: "vault", src: "Vault", params: { _vaultFactory: VF, _comptroller: comptroller } },
        // ])

        // expect(ctx.vault).not.to.be.undefined
        // expect(ctx.vault.address).not.to.be.undefined
        // let vaultAddress = ctx.vault.address

        // console.log("initialize vault")
        // await ctx.execute("master", "eth", "approve", {
        //     spender: VF, amount: { low: 1000000000000000n, high: 0 }
        // })

        // await ctx.loadContracts([
        //     { name: "vault", src: "Vault", address: "0x24a52c2f65fab7b7e00bf5c69d5f9bf2a95ba9bbddbcbbebb031b8fb9e626e9" },
        // ])

        // console.log(getSelectorFromName("setNewMint"))
        // console.log(getSelectorFromName("setNewBurn"))
        // console.log(getSelectorFromName("getDaoTreasury"))
        // console.log(getSelectorFromName("getStackingVault"))
        // console.log(getSelectorFromName("getValueInterpretor"))
        // console.log(getSelectorFromName("getPolicyManager"))
        // console.log(getSelectorFromName("getFeeManager"))
        // console.log(getSelectorFromName("getIntegrationManager"))

        // 0x220c15921b0635e30a04641ac980a3ea6e34ec5c5b5e10a8197ed13f18f1b79
        // 0x0389db1d3c2523fa790791a8885a1ac51db53c694aa1a173c8d0fa1adbccdcb5
        // await ctx.execute("master", "alphaRoadFinanceLP", "setIARFSwapController", {
        //     _IARFSwapController: ARFSwapControlleur,
        // })


        // await ctx.execute("master", "vaultFactory", "setStackingVault", {
        //     _stackingVault: "0x24a52c2f65fab7b7e00bf5c69d5f9bf2a95ba9bbddbcbbebb031b8fb9e626e9"
        // })
        // await ctx.execute("master", "vaultFactory", "setDaoTreasury", {
        //     _daoTreasury: '0x048f24b4Dd688cd9F6f2a9c47bc7185BAf34e1530215d05A4A7C4c761BC41E56'
        // })

        // await ctx.execute("master", "eth", "approve", {
        //     spender: comptroller, amount: { low: "1000000000000000", high: "0" }
        // })

        // console.log("watchh")

        // await ctx.execute("master", "comptroller", "sell_share", {
        //     _vault: "0x5c77df4511c59735cddae2afee8d0a217bd12245fb0e2dd76654cf8ce38f8ef", token_id: { low: "1000000000000000", high: "0" }, share_amount: { low: "1000000000000000", high: "0" }, assets: [], percents: []
        // })



        // await ctx.execute("master", "vaultFactory", "initializeFund", {
        //     _vault: ctx.vault.address, _fundName: felt("myamazingfund"), _fundSymbol: felt("FND"), _denominationAsset: Eth, _positionLimitAmount: { low: 250n, high: 0 }, _amount: { low: 1000000000000000, high: 0 }, _shareAmount: { low: 10000000000000000000n, high: 0 }, _feeConfig: [0, 0, 10, 10], _assetList: [Eth, BTC, ZKP, TST, Eth_ZKP, ETH_TST, ETH_BTC], _externalPositionList: [], _integration: [{ contract: ARFSwapControlleur, selector: swapExactTokensForTokens, integration: ARFSwap },
        //     { contract: ARFSwapControlleur, selector: addLiquidity, integration: ARFLiquidity },
        //     { contract: ARFSwapControlleur, selector: removeLiquidity, integration: "0" }], _minAmount: { low: 1000000000000000n, high: 0 }, _maxAmount: { low: 1000000000000000000000n, high: 0 }, _timelock: 150, _isPublic: 1
        // })>


        // await ctx.execute("master", "eth", "transfer", {
        //     recipient: "0x46545453", amount: { low: "100000000", high: "0" }
        // })

        // await ctx.execute("master", "eth", "approve", {
        //     spender: VF, amount: { low: "1000000000000000", high: "0" }
        // })

        // await ctx.execute("master", "vaultFactory", "initializeFund", {
        //     _vault: "3301742106946836676167360164139510965302384038822106306178094734644850983137", _fundName: "402263585231290935318042377794711140", _fundSymbol: "5062982", _denominationAsset: "2087021424722619777119509474943472645767659996348769578120564519014510906823", _positionLimitAmount: { low: "100", high: "0" }, _amount: { low: "1000000000000000", high: "0" }, _shareAmount: { low: "13000000000000000000", high: "0" }, _feeConfig: ["0", "0", "10", "5"], _assetList: ['2087021424722619777119509474943472645767659996348769578120564519014510906823', '3247388024922748134843608892309699741875987881237106590599513207337606053879', '3461017944318571556864544012524891952771668393835727350718440246043171699180', '3082294864746568851406914180133476690837611278875248474116062947635320909256', '2966556504830279170460168135386101745805819456409239616608027650491469804478', '3267429884791031784129188059026496191501564961518175231747906707757621165072', '936456946073074950586556312596957633951280930218232689661811534901843911747', '2770174426030749006759999589934377255706081509516375365733662619363094133061'], _externalPositionList: [], _integration: [{ contract: "0x4aec73f0611a9be0524e7ef21ab1679bdf9c97dc7d72614f15373d431226b6a", selector: '0x2c0f7bf2d6cf5304c29171bf493feb222fef84bdaf17805a6574b0c2e8bcc87', integration: "0" }, { contract: "0x4aec73f0611a9be0524e7ef21ab1679bdf9c97dc7d72614f15373d431226b6a", selector: '0x3f35dbce7a07ce455b128890d383c554afbc1b07cf7390a13e2d602a38c1a0a', integration: '0' }, { contract: "0x4aec73f0611a9be0524e7ef21ab1679bdf9c97dc7d72614f15373d431226b6a", selector: "0x147fd8f7d12de6da66feedc6d64a11bd371e5471ee1018f11f9072ede67a0fa", integration: "0" }], _minAmount: { low: "100000000000000", high: "0" }, _maxAmount: { low: "20000000000000000000", high: "0" }, _timelock: "24", _isPublic: "0"
        // })
    });

    // 1468441269974150507706747570871644292637471550256593800446589347998711897797', '402263585219182916351111233206054500', '5062982', '2087021424722619777119509474943472645767659996348769578120564519014510906823', '100', '0', '105000000000000', '0', '13000000000000000000', '0', '4', '0', '0', 10, 5, '8', '2087021424722619777119509474943472645767659996348769578120564519014510906823', '3247388024922748134843608892309699741875987881237106590599513207337606053879', '3461017944318571556864544012524891952771668393835727350718440246043171699180', '3082294864746568851406914180133476690837611278875248474116062947635320909256', '2966556504830279170460168135386101745805819456409239616608027650491469804478', '3267429884791031784129188059026496191501564961518175231747906707757621165072', '936456946073074950586556312596957633951280930218232689661811534901843911747', '2770174426030749006759999589934377255706081509516375365733662619363094133061', '0', '3', '0x4aec73f0611a9be0524e7ef21ab1679bdf9c97dc7d72614f15373d431226b6a', '0x2c0f7bf2d6cf5304c29171bf493feb222fef84bdaf17805a6574b0c2e8bcc87', '0', '0x4aec73f0611a9be0524e7ef21ab1679bdf9c97dc7d72614f15373d431226b6a', '0x3f35dbce7a07ce455b128890d383c554afbc1b07cf7390a13e2d602a38c1a0a', '0', '0x4aec73f0611a9be0524e7ef21ab1679bdf9c97dc7d72614f15373d431226b6a', '0x147fd8f7d12de6da66feedc6d64a11bd371e5471ee1018f11f9072ede67a0fa', '0', '100000000000000', '0', '20000000000000000000', '0', 24, '0'

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
