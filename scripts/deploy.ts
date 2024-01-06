import { ethers } from "hardhat";

async function main() {
  const [owner, signer, ethscriber] = await ethers.getSigners();

  console.log(`Got owner: ${owner.address}`);
  console.log(`Got signer: ${signer.address}`);
  console.log(`Got ethscriber: ${ethscriber.address}`);

  const factory = await ethers.deployContract("SkrybeFactory", [signer, ethscriber], owner);
  console.log('Deployed Factory');
  await factory.waitForDeployment();
  console.log('Factory Deployed');

  const address = await factory.getAddress();

  console.log(`Deployed Factory with Address: ${address}`);


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
