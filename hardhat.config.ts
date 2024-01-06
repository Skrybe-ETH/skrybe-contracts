import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.21",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  gasReporter: {
    enabled: true,
    currency: 'USD',
    gasPrice: 25
  },
  networks: {
    hardhat: {
      chainId: 1337,
    }
  },
};

export default config;
