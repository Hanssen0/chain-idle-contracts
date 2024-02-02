import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import { readFileSync } from "fs";

const arbSepoliaMnemonic = (() => {
  try {
    return readFileSync("./arbSepolia.mnemonic").toString().trim();
  } catch (error) {
    return "test test test test test test test test test test test junk";
  }
})();

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    arbSepolia: {
      url: "https://sepolia-rollup.arbitrum.io/rpc",
      accounts: {
        mnemonic: arbSepoliaMnemonic,
      }
    }
  }
};

export default config;
