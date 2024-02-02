import {
  loadFixture,
  time,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ethers, upgrades } from "hardhat";
import { expect } from "chai";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { Game } from "../typechain-types";

async function deployFixture() {
  const [owner] = await ethers.getSigners();

  const Game = await ethers.getContractFactory("Game");
  const game = await upgrades.deployProxy(Game, [owner.address], {
    initializer: "initialize",
    kind: "uups",
  });

  return { game: game as unknown as Game };
}

describe("Game", () => {
  describe("Deployment", () => {
    let game: Game;
    let owner: HardhatEthersSigner;

    before(async () => {
      game = (await loadFixture(deployFixture)).game;
      owner = (await ethers.getSigners())[0];
    });

    it("Should be deployed with owner set", async () => {
      expect(await game.owner()).to.equal(owner.address);
    });
  });

  describe("Normal play", () => {
    let game: Game;
    let playerSigner: HardhatEthersSigner;

    before(async () => {
      game = (await loadFixture(deployFixture)).game;
      playerSigner = (await ethers.getSigners())[1];
    });

    it("Should returns default player", async () => {
      const player = await game.getPlayer(playerSigner.address);
      expect(player.stage).to.equals(0n);
    });

    it("Should init player", async () => {
      await game.connect(playerSigner).initPlayer({
        mantissa: 10n ** 18n,
        depth: 1n,
        exponent: 6n * 10n ** 18n,
      });
      const latest = await time.latest();
      const player = await game.getPlayer(playerSigner.address);
      expect(player.stage).to.equals(1n);
      expect(player.ideas.mantissa).to.equals(955n * 10n ** 16n);
      expect(player.ideas.depth).to.equals(1n);
      expect(player.ideas.exponent).to.equals(5n * 10n ** 18n);
      expect(player.dt).to.equals(1n);
      expect(player.xLevel).to.equals(10n);
      expect(player.lastTimestamp).to.equals(BigInt(latest));
    });

    it("Should update blocks", async () => {
      const before = await game.getPlayer(playerSigner.address);
      await time.setNextBlockTimestamp(Number(before.lastTimestamp) + 1);
      await game.connect(playerSigner).updateBlocks();

      const player = await game.getPlayer(playerSigner.address);
      expect(player.lastTimestamp).to.equals(before.lastTimestamp + 1n);
      expect(player.blocks.mantissa).to.equals(10005n * 10n ** 14n);
      expect(player.blocks.depth).to.equals(1n);
      expect(player.blocks.exponent).to.equals(6n * 10n ** 18n);
      expect(player.ideas.mantissa).to.equals(9555n * 10n ** 15n);
      expect(player.ideas.depth).to.equals(1n);
      expect(player.ideas.exponent).to.equals(5n * 10n ** 18n);
    });

    it("Should purchase X", async () => {
      const before = await game.getPlayer(playerSigner.address);
      await time.setNextBlockTimestamp(Number(before.lastTimestamp) + 1);
      await game.connect(playerSigner).purchaseX();

      const player = await game.getPlayer(playerSigner.address);
      expect(player.lastTimestamp).to.equals(before.lastTimestamp + 1n);
      expect(player.blocks.mantissa).to.equals(1001n * 10n ** 15n);
      expect(player.blocks.depth).to.equals(1n);
      expect(player.blocks.exponent).to.equals(6n * 10n ** 18n);
      expect(player.ideas.mantissa).to.equals(946n * 10n ** 16n);
      expect(player.ideas.depth).to.equals(1n);
      expect(player.ideas.exponent).to.equals(5n * 10n ** 18n);
      expect(player.xLevel).to.equals(before.xLevel + 1n);
    });
  });
});
