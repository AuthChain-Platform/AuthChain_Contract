import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";

dotenv.config();

// Add this check to ensure private key exists
if (!process.env.ACCOUNT_PRIVATE_KEY) {
  throw new Error("Please set your ACCOUNT_PRIVATE_KEY in a .env file");
}

const config: HardhatUserConfig = {
  solidity: "0.8.27",
  networks: {
    // for testnet
    "lisk-sepolia": {
      url: "https://rpc.sepolia-api.lisk.com/",
      accounts: [`0x${process.env.ACCOUNT_PRIVATE_KEY}`], // Add '0x' prefix if needed
      // or alternatively: accounts: [process.env.ACCOUNT_PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: {
      "lisk-sepolia": "123",
    },
    customChains: [
      {
        network: "lisk-sepolia",
        chainId: 4202,
        urls: {
          apiURL: "https://sepolia-blockscout.lisk.com/api",
          browserURL: "https://sepolia-blockscout.lisk.com/",
        },
      },
    ],
  },
  sourcify: {
    enabled: false,
  },
};

export default config;