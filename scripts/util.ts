import fs from "fs"
import hardhat from "hardhat";
import { StarknetContract, Account } from "hardhat/types";
import { number } from "starknet"

let contract;
const starknet = hardhat.starknet;
interface IAccount extends Account {
    address: string
}

interface IContractInfo {
    name: string;
    src: string;
    params: Object;

}

export async function deployAccounts(ctx: any, names: string[]) {
    const promiseContainer = names.map(name => starknet.deployAccount("OpenZeppelin"))
    const accounts: IAccount[] = (await Promise.all(promiseContainer)).map((account: any) => { account.address = account.starknetContract.address; return account })
    for (let i in accounts) {
        ctx[names[i]] = accounts[i]
    }
}

export function getInitialContext() {
    let ctx: any = {}
    ctx.deployContracts = async (contractInfos: IContractInfo[]) => {

        await deployContracts(ctx, contractInfos)
    }

    ctx.execute = async (_caller: string, _contract: string, selector: string, params: any) => {
        let account: IAccount = ctx[_caller]
        let contract: StarknetContract = ctx[_contract]

        let res = await account.invoke(contract, selector, params)
        return res
    }

    ctx.call = async (_caller: string, _contract: string, selector: string, params: any) => {
        let account: IAccount = ctx[_caller]
        let contract: StarknetContract = ctx[_contract]

        let res = await account.call(contract, selector, params)
        return res
    }

    ctx.deployAccounts = async (names: string[]) => {
        await deployAccounts(ctx, names)
    }
    return ctx
}


export async function deployContracts(ctx: any, contractInfos: IContractInfo[]) {
    console.log("deployContracts invoked")
    let promiseContainer: Promise<StarknetContract>[] = []
    for (let i in contractInfos) {
        const { name, src, params } = contractInfos[i]
        const contractPromise: Promise<StarknetContract> = new Promise(async (resolve, reject) => {
            console.log("promise started")
            try {
                const contractFactory = await starknet.getContractFactory(src)
                console.log("contract factory getted")
                const contract = await contractFactory.deploy(params)
                console.log("contract factory deployed")
                resolve(contract)
            }
            catch (err) {
                reject(err)
            }
        })
        promiseContainer.push(contractPromise)
    }
    console.log("waiting promise all awaited")
    const result = await Promise.all(promiseContainer)
    console.log("finished promise all awaited")

    for (let i in result) {
        const { name, src, params } = contractInfos[i]
        const contract = result[i]
        ctx[name] = contract
        console.log(`contract ${name} has been added to the context, address ${contract.address}`)
    }
}
// name : felt,
// symbol : felt,
// decimals : felt,
// initial_supply : Uint256,
// recipient : felt,
// owner : felt,

export async function deployContext() {
    let ctx: any = {}
    await deployAccounts(ctx, ["alice", "bob", "carol", "dave", "amber", "kim", "shane"])
    console.log("alice", ctx.alice.starknetContract._address)
    return
    await deployContracts(ctx, [
        // deploy tokens
        { name: "usdt", src: "ERC20", params: { name: felt("usdt"), symbol: felt("usdt"), decimals: 2, initial_supply: { low: 100000, high: 0 }, recipient: felt(ctx.alice.address), owner: felt(ctx.alice.address) } },
        { name: "dai", src: "ERC20", params: { name: felt("dai"), symbol: felt("dai"), decimals: 2, initial_supply: { low: 100000, high: 0 }, recipient: felt(ctx.alice.address), owner: felt(ctx.alice.address) } },
        { name: "weth", src: "ERC20", params: { name: felt("weth"), symbol: felt("weth"), decimals: 2, initial_supply: { low: 100000, high: 0 }, recipient: felt(ctx.alice.address), owner: felt(ctx.alice.address) } },
        // deploy extensions
        { name: "feeManager", src: "FeeManager", params: {} },
        { name: "policyManager", src: "FeeManager", params: {} },
    ])


    return ctx
}


export function felt(str: string) {
    return starknet.shortStringToBigInt(str)
}
export function addr(str: string) {
    return number.toBN(str)
}

export function feltstr(str: string) {
    return number.toBN(str).toString()
}

export function felthex(str: string) {
    return number.toBN(str).toString("hex")
}

export function fromfelt(_felt: any) {
    return starknet.bigIntToShortString(_felt)
}

export const timer = (ms: any) => new Promise(res => setTimeout(res, ms))

