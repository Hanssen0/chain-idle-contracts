import { ethers, upgrades } from "hardhat";
import { getDeployed, saveToFile } from "./utils";

async function main() {
  const [owner] = await ethers.getSigners();

  const Game = await ethers.getContractFactory("Game");

  const deployed = await getDeployed("Game");

  const game = await (() => {
    if (deployed) {
      return upgrades.upgradeProxy(deployed, Game, { kind: "uups" });
    }
    return upgrades.deployProxy(Game, [owner.address], {
      initializer: "initialize",
      kind: "uups",
    });
  })();

  await game.waitForDeployment();
  const address = await game.getAddress();

  await saveToFile(
    { address, owner: owner.address },
    "Game"
  );
  if (deployed) {
    console.log(`Game upgraded. ${address}`);
  } else {
    console.log(`Game deployed. ${address}`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
