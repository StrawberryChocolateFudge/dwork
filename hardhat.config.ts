import "hardhat-contract-sizer";
import "hardhat-gas-reporter";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-web3";
import "@nomiclabs/hardhat-solhint";
import "@typechain/hardhat";
import { task } from "hardhat/config";
import "hardhat-abi-exporter";

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (args, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
      {
        version: "0.8.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
    ],
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  },
  gasReporter: {
    currency: "CHF",
    gasPrice: 21,
    enabled: true,
  },
  typechain: {
    outDir: "worklinks.eth/types",
    target: "web3-v1",
    alwaysGenerateOverloads: true,
    externalArtifacts: ["artifacts/*.json"],
  },
  abiExporter: {
    path: "./worklinks.eth/abi",
    clear: true,
    flat: true,
    only: [],
    spacing: 2,
  },
};
