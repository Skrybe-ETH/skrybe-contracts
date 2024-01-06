import { ethers } from "hardhat";
import { config } from "dotenv";
import { parseEther } from "ethers";
config();

const PRICE = parseEther('0.02');
const MAX_SUPPLY = 10_000;
const MAX_PER_TXN = 0;
const MAX_PER_WHITELIST = 0;
const WHITELIST_PRICE = parseEther('0.01');
const BASE_FEE = parseEther('0.0005');
const ETHSCRIPTION_BASE_FEE = parseEther('0.00035');

async function main() {
    const [owner, signer, ethscriber] = await ethers.getSigners();
    const factory = await ethers.getContractAt('SkrybeFactory', process.env.FACTORY_CONTRACT_ADDRESS || '');

    const structData =
        ethers.AbiCoder.defaultAbiCoder().encode(
            ['uint256', 'uint256', 'uint256', 'uint256', 'uint256', 'uint256'],
            [PRICE, 0, MAX_SUPPLY, MAX_PER_TXN, MAX_PER_WHITELIST, 0]
        );
    const message = ethers.getBytes(ethers.keccak256(
        ethers.AbiCoder.defaultAbiCoder().encode(
            ['address', 'string', 'string'],
            [owner.address, structData, "CREATE"]
        )
    ));
    const sig = await signer.signMessage(message);

    const txn = await factory.createCollection(
        {
            "price": PRICE,
            "whitelistPrice": 0,
            "maxSupply": MAX_SUPPLY,
            "maxPerTxn": MAX_PER_TXN,
            "maxPerWhitelist": MAX_PER_WHITELIST,
            "usesWhitelist": 0
          },
          ETHSCRIPTION_BASE_FEE,
          structData,
          sig
    );
    
    await txn.wait();

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
