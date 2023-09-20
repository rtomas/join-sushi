import { expect } from "chai";
import { ethers } from "hardhat";

import { Contract, Signer } from "ethers";

import { IERC20__factory, SushiSwapLiquidityInteract, IUniswapV2Router01, IMasterChefV2 } from "../typechain-types";
const helpers = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");

const UNISWAP_ROUTER = "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F";
const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const MASTERCHEF_V1 = "0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd";
const MASTERCHEF_V2 = "0xEF0881eC094552b2e128Cf945EF17a6752B4Ec5d";
const VITALIK_ACCOUNT = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045";
const IS_MASTERCHEF_V1 = true;

describe("SushiSwapLiquidityInteract", function () {
    async function deployFixture() {
        let owner: Signer;
        let tokenA, tokenB: Contract;
        let sushiSwapLiquidityContract: SushiSwapLiquidityInteract;
        let router: IUniswapV2Router01;

        // Impersonate vitalik account that has DAI and WETH
        owner = await ethers.getSigner(VITALIK_ACCOUNT);
        await helpers.impersonateAccount(VITALIK_ACCOUNT);

        tokenA = await new ethers.Contract(WETH, IERC20__factory.abi, owner);
        tokenB = await new ethers.Contract(DAI, IERC20__factory.abi, owner);

        // Deploy the SushiSwapLiquidityInteract contract
        const SushiSwapLiquidityInteract = await ethers.getContractFactory("SushiSwapLiquidityInteract", owner);
        sushiSwapLiquidityContract = await SushiSwapLiquidityInteract.deploy(UNISWAP_ROUTER, tokenA, tokenB, MASTERCHEF_V1, IS_MASTERCHEF_V1);

        // Get deployed UniswapV2Router01 contract
        router = await ethers.getContractAt("IUniswapV2Router01", UNISWAP_ROUTER);

        return { owner, tokenA, tokenB, sushiSwapLiquidityContract, router };
    }

    before(async function () {});

    it("should add Liquidity and stake LP", async function () {
        const { owner, tokenA, tokenB, sushiSwapLiquidityContract, router } = await loadFixture(deployFixture);

        // Transfer tokens to the SushiSwapLiquidityInteract contract
        let amountA = 24920000;
        let amountB = 9000000000000;
        let pid = 2; // for DAI-WETH pair

        await tokenA.transfer(sushiSwapLiquidityContract, amountA);
        await tokenB.transfer(sushiSwapLiquidityContract, amountB);

        await sushiSwapLiquidityContract.JoinLiquidity(amountA, amountB, pid);

        // expected amount of LP tokens
        const mc = await ethers.getContractAt("IMasterChef", MASTERCHEF_V1);
        const info = await mc.userInfo(pid, sushiSwapLiquidityContract);

        expect(info[0].toString()).to.equal("698205729");
    });

    it("should error as amount of token A is 0", async function () {
        const { owner, tokenA, tokenB, sushiSwapLiquidityContract, router } = await loadFixture(deployFixture);

        // Transfer tokens to the SushiSwapLiquidityInteract contract
        let amountA = 0;
        let amountB = 9000000000000;
        let pid = 2; // for DAI-WETH pair

        await tokenA.transfer(sushiSwapLiquidityContract, amountA);
        await tokenB.transfer(sushiSwapLiquidityContract, amountB);

        // expected error as amountA is 0
        await expect(sushiSwapLiquidityContract.JoinLiquidity(amountA, amountB, pid)).to.be.revertedWith("Invalid TokenA Supply");
    });

    it("should error as amount of token B is 0", async function () {
        const { owner, tokenA, tokenB, sushiSwapLiquidityContract, router } = await loadFixture(deployFixture);

        // Transfer tokens to the SushiSwapLiquidityInteract contract
        let amountA = 2220;
        let amountB = 0;
        let pid = 2; // for DAI-WETH pair

        await tokenA.transfer(sushiSwapLiquidityContract, amountA);
        await tokenB.transfer(sushiSwapLiquidityContract, amountB);

        // expected error as amountB is 0
        await expect(sushiSwapLiquidityContract.JoinLiquidity(amountA, amountB, pid)).to.be.revertedWith("Invalid TokenB Supply");
    });

    it("should error as not enough funds of token B are in the contract", async function () {
        const { owner, tokenA, tokenB, sushiSwapLiquidityContract, router } = await loadFixture(deployFixture);

        // Transfer tokens to the SushiSwapLiquidityInteract contract
        let amountA = 2220;
        let amountB = 9000000000000;
        let pid = 2; // for DAI-WETH pair

        await tokenA.transfer(sushiSwapLiquidityContract, 2220);
        await tokenB.transfer(sushiSwapLiquidityContract, 0);

        // expected error as amountB is 0
        await expect(sushiSwapLiquidityContract.JoinLiquidity(amountA, amountB, pid)).to.be.revertedWith("Insuficient Balance TokenB");
    });
});
