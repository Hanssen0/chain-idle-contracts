import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ethers } from "hardhat";
import { expect } from "chai";

describe("Game", () => {
  async function deployFixture() {
    const Game = await ethers.getContractFactory("Game");
    const game = await Game.deploy();

    return { game };
  }

  describe("Deployment", () => {
    it("Should be deployed", async () => {
      const { game } = await loadFixture(deployFixture);

      expect(game).to.not.equal(null);
    });
  });
});
