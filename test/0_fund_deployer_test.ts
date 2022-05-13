import { expect } from "chai";
import { starknet } from "hardhat";
import { StarknetContract, StarknetContractFactory } from "hardhat/types/runtime";
import { TIMEOUT } from "./constants";
import { startListener } from "../scripts/event";
import { felthex, feltstr, addr, fromfelt, timer, felt, deployAccounts, deployContracts, getInitialContext } from "../scripts/util";

// analyse event and do callBack

describe("FundDeployer", function () {
    this.timeout(TIMEOUT);
    let ctx: any = getInitialContext()
    console.log("ctx getted")
    it("should deploy fund_deployer & comptroller_lib & fee_manager", async function () {
        await ctx.deployContracts([
            { name: "fund_deployer", src: "VaultFactory", params: {} },
            { name: "comptroller_lib", src: "ComptrollerLib", params: {} },
            { name: "fee_manager", src: "FeeManager", params: {} },
        ])
        const contractFactory = await starknet.getContractFactory("ComptrollerLib")
        const contract = await contractFactory.deploy()

        expect(ctx.fund_deployer).not.to.be.undefined
        expect(ctx.comptroller_lib).not.to.be.undefined
        expect(ctx.fee_manager).not.to.be.undefined
        expect(ctx.fund_deployer.address).not.to.be.undefined
        expect(ctx.comptroller_lib.address).not.to.be.undefined
        expect(ctx.fee_manager.address).not.to.be.undefined

        console.log(`fund-deployer addr: ${ctx.fund_deployer.address}`)
        console.log(`comptroller-lib addr: ${ctx.comptroller_lib.address}`)
        console.log(`fee-manager addr: ${ctx.fee_manager.address}`)


        async function handleEvent(event: any) {
            console.log("handleEvent invoked")
            let FundDeployerEvents = {
                CREATE_VAULT: 0,
                REMOVE_VAULT: 1,
            }

            let eventType = parseInt(event.data[0], 16)
            let vault_addr = event.data[1]

            if (eventType == FundDeployerEvents.CREATE_VAULT) {
                console.log("CREATE_VAULT event emitted")
                const { version, address } = await ctx.fund_deployer.call("get_latest_comptroller_version", {})
                let vault = felthex(vault_addr);
                console.log(`version ${version} address ${address}`)

                let pro = ctx.fund_deployer.invoke("set_vault_comptrollerd", { vault, comptroller_address: address })
                console.log("promise", pro)
                await pro
                console.log("set_vault_comptroller invoked completely")
                const { comptroller } = await ctx.fund_deployer.call("get_vault_comptroller", { vault })
                console.log("comptroller after deploy", comptroller)
            }
            else if (eventType == FundDeployerEvents.REMOVE_VAULT) {
                console.log("REMOVE_VAULT event emitted")
            }
        }

        startListener(ctx.fund_deployer.address, handleEvent)
    });

    it("Should setup fee manager to fund_deployer", async () => {
        console.log(addr(ctx.fee_manager.address).toString())
        console.log(addr(ctx.fee_manager.address).toString("hex"))
        await ctx.fund_deployer.invoke("setFeeManager", { _feeManager: addr(ctx.fee_manager.address) })
        const { res: fee_manager_addr } = await ctx.fund_deployer.call("getFeeManager", {})
        console.log("fee_manager", addr(fee_manager_addr).toString())
        expect(feltstr(fee_manager_addr)).to.be.equal(addr(ctx.fee_manager.address).toString())

    })
    it("Should add comptroller version to fund_deployer", async () => {
        await ctx.fund_deployer.invoke("add_comptroller_version", { comptroller: addr(ctx.comptroller_lib.address) })
        const { version, address } = await ctx.fund_deployer.call("get_latest_comptroller_version", {})
        expect(feltstr(version)).to.be.equal("1")
        expect(feltstr(address)).to.be.equal(feltstr(ctx.comptroller_lib.address))
    })

    it("Should create accounts", async () => {
        await ctx.deployAccounts(["alice", "bob", "carol", "dave"])
        expect(ctx.alice).not.to.be.undefined
        expect(ctx.bob).not.to.be.undefined
        expect(ctx.carol).not.to.be.undefined
        expect(ctx.dave).not.to.be.undefined
        console.log(ctx.alice.address)
    })

    it("should create vault", async () => {
        const _fundName = felt("vault0")
        const _fundSymbol = felt("vault0")
        const _deno = felt("usdt")
        console.log("alice", ctx.alice.address)
        await ctx.execute("alice", "fund_deployer", "createNewFund", {
            _fundName, _fundSymbol, _denominationAsset: _deno
        })

        // await timer(80000)
        // await timer(80000)

        for (let i = 0; i < 1000; i++) {
            await timer(1000)
            const { version, address } = await ctx.fund_deployer.call("get_latest_comptroller_version", {})

            // await ctx.fund_deployer.invoke("set_vault_comptroller", { vault: addr(ctx.alice.address), comptroller_address: address })

            let { comptroller } = await ctx.call("alice", "fund_deployer", "get_vault_comptroller", { vault: addr(ctx.alice.address) })
            console.log("comptroller", comptroller)
            if (feltstr(comptroller) != "0")
                break
            // expect(feltstr(comptroller)).not.to.be.undefined
            // expect(feltstr(comptroller)).to.be.equal(feltstr(ctx.comptroller_lib.address))
        }
    })
});
