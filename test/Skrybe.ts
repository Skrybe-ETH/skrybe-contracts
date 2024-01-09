import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { parseEther } from "ethers";

const PRICE = parseEther('0.02');
const MAX_SUPPLY = 10_000;
const MAX_PER_TXN = 0;
const MAX_PER_WHITELIST = 0;
const WHITELIST_PRICE = parseEther('0.01');
const BASE_FEE = parseEther('0.0005');
const ETHSCRIPTION_BASE_FEE = parseEther('0.00035');

describe("SkrybeFactory", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.

  async function deploySkrybeFactory() {
    const [deployer, ethscriber, signer, user] = await ethers.getSigners();

    const Factory = await ethers.getContractFactory("SkrybeFactory");
    const factory = await Factory.deploy(signer, ethscriber);

    return { factory, signer, ethscriber, user };
  }

  describe("Creation", function () {
    it("Should correctly create a collection and emit event.", async function () {
      const { factory, signer, user } = await loadFixture(deploySkrybeFactory);

      const message = ethers.getBytes(ethers.keccak256(
        ethers.AbiCoder.defaultAbiCoder().encode(
          ['address', 'string', 'string'],
          [user.address, "test", "CREATE"]
        )
      ));
      const sig = await signer.signMessage(message);

      expect(await factory.connect(user).createCollection(
        {
          "collectionId": "test",
          "launchTimestamp": new Date().getTime(),
          "whitelistLaunchTimestamp": 0,
          "price": PRICE,
          "whitelistPrice": 0,
          "maxSupply": MAX_SUPPLY,
          "maxPerTxn": MAX_PER_TXN,
          "maxPerWhitelist": MAX_PER_WHITELIST,
          "maxPerWallet": 0,
          "usesWhitelist": 0
        },
        ETHSCRIPTION_BASE_FEE,
        sig
      )).to.emit(factory, 'CollectionCreated');

    });

    it("Should not allow invalid signatures.", async function () {
      const { factory, user } = await loadFixture(deploySkrybeFactory);

      const structData =
        ethers.AbiCoder.defaultAbiCoder().encode(
          ['uint256', 'uint256', 'uint256', 'uint256', 'uint256', 'uint256'],
          [PRICE, 0, MAX_SUPPLY, MAX_PER_TXN, MAX_PER_WHITELIST, 0]
        );
      const message = ethers.getBytes(ethers.keccak256(
        ethers.AbiCoder.defaultAbiCoder().encode(
          ['address', 'string', 'string'],
          [user.address, structData, "CREATE"]
        )
      ));
      const sig = await user.signMessage(message);

      await expect(factory.connect(user).createCollection(
        {
          "collectionId": "test",
          "launchTimestamp": new Date().getTime(),
          "whitelistLaunchTimestamp": 0,
          "price": PRICE,
          "whitelistPrice": 0,
          "maxSupply": MAX_SUPPLY,
          "maxPerTxn": MAX_PER_TXN,
          "maxPerWhitelist": MAX_PER_WHITELIST,
          "maxPerWallet": 0,
          "usesWhitelist": 0
        },
        ETHSCRIPTION_BASE_FEE,
        sig
      )).to.be.revertedWithCustomError(factory, 'InvalidCreationSignature()');
    });
  })


});
