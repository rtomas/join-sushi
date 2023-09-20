import { expect } from "chai";
import { ethers } from "hardhat";

import { Contract, Signer } from "ethers";

import { IERC20__factory, SushiSwapLiquidityInteract, IUniswapV2Router01, IMasterChefV2 } from "../typechain-types";
const helpers = require("@nomicfoundation/hardhat-toolbox/network-helpers");

const UNISWAP_ROUTER = "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F";
const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const MASTERCHEF_V1 = "0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd";
const MASTERCHEF_V2 = "0xEF0881eC094552b2e128Cf945EF17a6752B4Ec5d";
const VITALIK_ACCOUNT = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045";
const IS_MASTERCHEF_V1 = false;

describe("SushiSwapLiquidityInteract", function () {
    let owner: Signer;
    let tokenA: Contract;
    let tokenB: Contract;
    let sushiSwapLiquidityContract: SushiSwapLiquidityInteract;
    let router: IUniswapV2Router01;

    before(async function () {
        // Impersonate vitalik account that has DAI and WETH
        owner = await ethers.getSigner(VITALIK_ACCOUNT);
        await helpers.impersonateAccount(VITALIK_ACCOUNT);

        tokenA = await new ethers.Contract(WETH, IERC20__factory.abi, owner);
        tokenB = await new ethers.Contract(DAI, IERC20__factory.abi, owner);

        // Deploy the SushiSwapLiquidityInteract contract
        const SushiSwapLiquidityInteract = await ethers.getContractFactory("SushiSwapLiquidityInteract", owner);
        sushiSwapLiquidityContract = await SushiSwapLiquidityInteract.deploy(UNISWAP_ROUTER, tokenA, tokenB, MASTERCHEF_V2, IS_MASTERCHEF_V1);

        // Get deployed UniswapV2Router01 contract
        router = await ethers.getContractAt("IUniswapV2Router01", UNISWAP_ROUTER);

        // get balance of tokenA for owner
        const balanceA = await tokenA.balanceOf(owner.getAddress());
        console.log("balanceA: ", balanceA.toString());

        // get balance of tokenB for owner
        const balanceB = await tokenB.balanceOf(owner.getAddress());
        console.log("balanceB: ", balanceB.toString());
    });

    it("should add Liquidity and stake LP", async function () {
        // Transfer tokens to the SushiSwapLiquidityInteract contract
        let amountA = 24920000;
        let amountB = 9000000000000;
        await tokenA.transfer(sushiSwapLiquidityContract, amountA);
        await tokenB.transfer(sushiSwapLiquidityContract, amountB);

        await sushiSwapLiquidityContract.JoinLiquidity(amountA, amountB);

        // TODO: expected amount of LP tokens
    });
});
