import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ethers";
require("dotenv").config();

const API_URL = process.env.API_URL || "";

const config: HardhatUserConfig = {
    solidity: "0.8.19",
    networks: {
        hardhat: {
            forking: {
                url: API_URL,
                blockNumber: 15250400,
            },
        },
    },
};

export default config;
