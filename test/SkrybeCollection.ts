import {
    time,
    loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { parseEther } from "ethers";

const COLLECTION_ID = "test-collection-id";
const PUBLIC_PRICE = parseEther('0.0001');
const WHITELIST_PRICE_FREE = parseEther('0');
const MAX_SUPPLY = 1000;
const MAX_PER_WALLET = 100;
const MAX_PER_TXN = 10;
const UNLIMITED_PER_TXN = 0;
const MAX_PER_WHITELIST = 10;
const UNLIMITED_PER_WHITELIST = 0;
const SKRYBE_FEE = parseEther('0.0005');
const ETHSCRIPTION_BASE_FEE = parseEther('0.00035');

describe("SkrybeCollection", function () {

    async function deploySkrybeFactoryAndCollection() {
        const [deployer, ethscriber, signer, user] = await ethers.getSigners();

        const Factory = await ethers.getContractFactory("SkrybeFactory");
        const factory = await Factory.deploy(signer.address, ethscriber.address);

        const msg = ethers.getBytes(ethers.keccak256(
            ethers.AbiCoder.defaultAbiCoder().encode(
                ['address', 'string', 'string'],
                [deployer.address, COLLECTION_ID, "CREATE"]
            )
        ));
        const sig = await signer.signMessage(msg);

        await factory.connect(deployer).createCollection(
            {
                collectionId: COLLECTION_ID,
                launchTimestamp: Math.floor(new Date().getTime() / 1000) + 5,
                whitelistLaunchTimestamp: 0,
                price: PUBLIC_PRICE,
                whitelistPrice: WHITELIST_PRICE_FREE,
                maxSupply: MAX_SUPPLY,
                maxPerTxn: UNLIMITED_PER_TXN,
                maxPerWhitelist: UNLIMITED_PER_WHITELIST,
                maxPerWallet: MAX_PER_WALLET,
                usesWhitelist: 0
            },
            ETHSCRIPTION_BASE_FEE,
            sig
        );

        const collection = await ethers.getContractAt("SkrybeCollection", await factory.collections(COLLECTION_ID));

        return { factory, collection, signer, ethscriber, user };
    }

    describe("Public", async function () {
        it("Should correctly mint a token and emit event.", async function () {
            const { collection, user } = await loadFixture(deploySkrybeFactoryAndCollection);

            await new Promise(resolve => setTimeout(resolve, 6000));

            expect(await collection.mint(1, { value: PUBLIC_PRICE + ETHSCRIPTION_BASE_FEE + SKRYBE_FEE })).to.emit(collection, 'Mint');
        });
    });


});