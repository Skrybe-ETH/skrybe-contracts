import { ethers } from "hardhat";

async function main() {
  const [owner, signer, ethscriber] = await ethers.getSigners();

  console.log(`Got owner: ${owner.address}`);
  console.log(`Got signer: ${signer.address}`);
  console.log(`Got ethscriber: ${ethscriber.address}`);

  const factory = await ethers.deployContract("SkrybeFactory", [signer, ethscriber], owner);
  console.log('Deployed Factory');

  const address = await factory.getAddress();

  console.log(`Deployed Factory with Address: ${address}`);

  // Sleep for 1 minutes
  await new Promise(resolve => setTimeout(resolve, 60000));
  const message = ethers.getBytes(ethers.keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(
      ['address', 'string', 'string'],
      [owner.address, "test", "CREATE"]
    )
  ));
  const sig = await signer.signMessage(message);
  await factory.connect(owner).createCollection(
    {
      "collectionId": "test",
      "launchTimestamp": new Date().getTime(),
      "whitelistLaunchTimestamp": 0,
      "price": 0,
      "whitelistPrice": 0,
      "maxSupply": 1000,
      "maxPerTxn": 1,
      "maxPerWhitelist": 0,
      "maxPerWallet": 0,
      "usesWhitelist": 0
    },
    1000000,
    sig
  )

  console.log('Created Collection');

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
