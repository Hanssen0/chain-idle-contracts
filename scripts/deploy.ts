import { ethers } from "hardhat";

async function main() {
  const game = await ethers.deployContract("Game");

  await game.waitForDeployment();

  console.log(`Game deployed to ${game.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
