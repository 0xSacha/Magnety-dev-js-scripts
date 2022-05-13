//@ts-nocheck
import hardhat from "hardhat";
import axios from "axios"
import { deployAccounts, deployContracts, deployContext } from "./util"
// async function main() {

//     const ctx = await deployContext()
//     console.log(ctx)
//     return

//     latestBlock = await getLatestBlock()

//     const contractFactory = await hardhat.starknet.getContractFactory("MockEmitter");
//     contract = await contractFactory.deploy();
//     console.log("Deployed tx:", contract.deployTxHash);
//     console.log("Deployed to:", contract.address);

//     startListener(contract)

//     // create FundDeployer after 2s
//     setTimeout(async () => {

//         // invoke create_vault contract to the testnet
//         let tx = await contract.invoke("create_vault", { owner: 111 });

//     }, 5000)

//     setTimeout(async () => {

//         // invoke remove_vault contract to the testnet
//         await contract.invoke("remove_vault", {});
//     }, 10000)

//     await timer(500000)
// }
const timer = ms => new Promise(res => setTimeout(res, ms))

export async function startListener(contractAddr, eventHandler) {
    latestBlock = await getLatestBlock()

    while (1) {
        console.log("get receipt...")
        await monitorContractEvents(contractAddr, eventHandler)
        // console.log("tr", tr)
        await timer(2000)
    }
}
let latestBlock = -1
const feederUrl = "http://localhost:5050/feeder_gateway/get_block?blockNumber="

export async function getLatestBlock() {
    const url = feederUrl + "null"
    let data = (await axios.get(url)).data
    if (data.status_code == 500)
        return -1
    return data.block_number
}
async function monitorContractEvents(contractAddr, eventHandler) {
    let blockNumber = await getLatestBlock()
    // if block_number - latestBlock > 1
    if (blockNumber == latestBlock)
        return
    while (latestBlock < blockNumber) {
        latestBlock++
        await scanEventTx(latestBlock, contractAddr, eventHandler)
    }
    // latestBlock ++
    // while latestBlock <= block_number
    // scanEvent(latestBlock, contractAddr, eventHandler)
    // get latest block number and save it
}

// analyse event and do callBack
async function handleEvent(event) {
    let FundDeployerEvents = {
        CREATE_VAULT: 0,
        REMOVE_VAULT: 1,
    }
    let eventType = parseInt(event.data[0], 16)

    if (eventType == FundDeployerEvents.CREATE_VAULT) {
        console.log("CREATE_VAULT event emitted")
    }
    else if (eventType == FundDeployerEvents.REMOVE_VAULT) {
        console.log("REMOVE_VAULT event emitted")
    }
}

// scan event in block txs and call event handler
async function scanEventTx(blockNum, contractAddr, eventHandler) {
    console.log("ScanEventTx in block " + blockNum)
    const url = feederUrl + blockNum
    let data = (await axios.get(url)).data
    // console.log(data.status !== "ACCEPTED_ON_L2")
    if (data.status !== "ACCEPTED_ON_L2")
        return
    // console.log("PASSED")
    // console.log(data.transaction_receipts)

    for (let index in data.transaction_receipts) {
        let tr = data.transaction_receipts[index]
        await analyseEventTx(tr, contractAddr, eventHandler)
    }
}

// analyseEventTx()
// analyse the event form tx
async function analyseEventTx(tx, contractAddr, eventHandler) {
    let events = tx.events
    // console.log(tx)
    // console.log(events)
    for (let index in events) {
        const ev = events[index]
        // console.log("ev", ev)

        if (ev.from_address.substr(2) === contractAddr.substr(3)) {
            eventHandler(ev)
        }
    }
}

// main()
//     .then(() => process.exit(0))
//     .catch((error) => {
//         console.error(error);
//         process.exit(1);
//     });
