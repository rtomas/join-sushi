/* import { time, loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai"; */
import { ethers } from "hardhat";

import { Contract, Signer, BaseContract } from "ethers";

//const SushiSwapLiquidityInteractABI = require("../artifacts/contracts/JoinSushi.sol/SushiSwapLiquidityInteract.json");
import { IERC20, IERC20__factory, IUniswapV2Router01__factory, SushiSwapLiquidityInteract, IUniswapV2Router01 } from "../typechain-types";
const helpers = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { setBalance } = require("@nomicfoundation/hardhat-network-helpers");

const UNISWAP_ROUTER = "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F";
const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const MASTERCHEF_V1 = "0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd";
const VITALIK_ACCOUNT = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045";
const IS_MASTERCHEF_V1 = true;

describe("SushiSwapLiquidityInteract", function () {
    let owner: Signer;
    let tokenA: Contract;
    let tokenB: Contract;
    let sushiSwapLiquidityContract: SushiSwapLiquidityInteract;
    let router: IUniswapV2Router01;

    before(async function () {
        // Impersonate vitalik account that has usdt and weth
        owner = await ethers.getSigner(VITALIK_ACCOUNT);

        await helpers.impersonateAccount(VITALIK_ACCOUNT);

        /* tokenA = await ethers.getContractAt("IERC20", WETH);
        tokenB = await ethers.getContractAt("IERC20", USDC); */
        tokenA = await new ethers.Contract(WETH, IERC20__factory.abi, owner);
        tokenB = await new ethers.Contract(USDC, IERC20__factory.abi, owner);

        // Deploy the SushiSwapLiquidityInteract contract
        const SushiSwapLiquidityInteract = await ethers.getContractFactory("SushiSwapLiquidityInteract", owner);

        sushiSwapLiquidityContract = await SushiSwapLiquidityInteract.deploy(UNISWAP_ROUTER, tokenA, tokenB, MASTERCHEF_V1, IS_MASTERCHEF_V1);

        router = await ethers.getContractAt("IUniswapV2Router01", UNISWAP_ROUTER);

        //get timestamp from block
        const block = await ethers.provider.getBlock("latest");
        const timestamp = block?.timestamp || 0;

        // get balance of tokenA for owner
        const balanceA = await tokenA.balanceOf(owner.getAddress());
        console.log("balanceA: ", balanceA.toString());

        // get balance of tokenB for owner
        const balanceB = await tokenB.balanceOf(owner.getAddress());
        console.log("balanceB: ", balanceB.toString());
    });

    it("should add Liquidity and stake LP", async function () {
        // Transfer tokens to the SushiSwapLiquidityInteract contract
        await tokenA.transfer(sushiSwapLiquidityContract, 400000000);
        await tokenB.transfer(sushiSwapLiquidityContract, 4000000);

        await sushiSwapLiquidityContract.JoinLiquidity(400000000, 4000000);
    });
});
