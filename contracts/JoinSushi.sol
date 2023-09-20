// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "./IERC20.sol";
import "./SushiSwap/IMasterChef.sol";
import "./SushiSwap/IMasterChefV2.sol";
import "./UniSwap/IUniswapV2Factory.sol";
import "./UniSwap/IUniswapV2Router01.sol";

import "hardhat/console.sol";

contract SushiSwapLiquidityInteract {
    address public owner;
    IUniswapV2Router01 public sushiRouter;
    IUniswapV2Factory public sushiFactory;
    IERC20 public tokenA; // Token you want to provide liquidity for
    IERC20 public tokenB; // Token you want to pair with tokenA
    address public masterChef; // Address of MasterChefV1 or MasterChefV2
    bool public isMasterChefV1; // Is the target MasterChef contract MasterChefV1 or MasterChefV2

    constructor(
        address _sushiRouter,
        address _tokenA,
        address _tokenB,
        address _masterChef,
        bool _isMasterChefV1
    ) {
        require(_tokenA != address(0), "Invalid Address");
        require(_tokenB != address(0), "Invalid Address");
        require(_tokenA != _tokenB, "Same Token Address");
        
        owner = msg.sender;
        sushiRouter = IUniswapV2Router01(_sushiRouter);
        sushiFactory = IUniswapV2Factory(sushiRouter.factory());
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        masterChef = _masterChef;
        isMasterChefV1 = _isMasterChefV1;
    }

    modifier OnlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function JoinLiquidity(uint256 _amountA, uint256 _amountB) public OnlyOwner {
        require(_amountA > 0, "Invalid TokenA Supply A");
        require(_amountB > 0, "Invalid TokenB Supply B");
        require(CheckBalance(tokenA) >= _amountA ,"Insuficient Balance TokenA");
        require(CheckBalance(tokenB) >= _amountB ,"Insuficient Balance TokenB");

        console.log("Init");
        approveSushiRouterToUseTokens(_amountA, _amountB);
        
        // log check allowance
        require(CheckAllowance(tokenA) >= _amountA ,"Insuficient Allowance A");
        require(CheckAllowance(tokenB) >= _amountB ,"Insuficient Allowance B");
        

        uint liquidity;
        uint pId;
        (_amountA, _amountB, liquidity, pId) = provideLiquidity(_amountA, _amountB);

        approveMasterChef(liquidity);
        depositLP(pId, liquidity);

        // TODO: Emit Event
    }

    /* function addLiquidityToSmartContract(
        uint256 amountA,
        uint256 amountB
    ) private OnlyOwner {
        IERC20(tokenA).transferFrom(owner, address(this), amountA);
        IERC20(tokenB).transferFrom(owner, address(this), amountB);
    } */

    // Step 1: Approve SushiSwap Router to spend tokens
    function approveSushiRouterToUseTokens(
        uint256 _amountA,
        uint256 _amountB
    ) private OnlyOwner {
        IERC20(tokenA).approve(address(sushiRouter), _amountA);
        IERC20(tokenB).approve(address(sushiRouter), _amountB);
    }

    // Step 2: Provide liquidity on SushiSwap
    function provideLiquidity(
        uint256 amountA,
        uint256 amountB
    ) private OnlyOwner returns (uint, uint, uint, uint) {
        // get length of pool
        uint256 length = sushiFactory.allPairsLength();


        //(uint256 a, uint256 b ) = sushiRouter.getReserves(sushiFactory, tokenA, tokenB);
        console.log("Length: %s", length);
        //uint256 valueA = sushiRouter.quote(amountB, amountB, amountA);
        uint256 valueA = sushiRouter.getAmountOut(amountB, amountB, amountA);


        console.log("Val: %s", valueA);
        (uint pAmountA, uint pAmountB, uint liquidity) =
            sushiRouter.addLiquidity(
                address(tokenA),
                address(tokenB),
                valueA,
                amountB,
                1, // Min amount of liquidity tokens you want to receive (set to 0)
                1, // Min amount of Sushi tokens you want to receive (set to 0)
                address(this),
                block.timestamp + 1000 * 60 * 5 // 5 minutes
            );
        // show all 
        console.log("pAmountA: %s", pAmountA);
        console.log("pAmountB: %s", pAmountB);
        console.log("liquidity: %s", liquidity);
        console.log("length: %s", length+1);
        return (pAmountA, pAmountB, liquidity, length+1);
    }

    // Step 3: Approve MasterChef to spend LP tokens
    function approveMasterChef(uint256 amountLP) private OnlyOwner {
        address addressPoolAB = getPoolPairAddressForTokens();
        IERC20(addressPoolAB).approve(masterChef, amountLP);
    }

    // Step 4: Deposit LP tokens into MasterChef
    function depositLP(uint pId, uint256 liquidity) private OnlyOwner {
        if (isMasterChefV1) {
            IMasterChef(masterChef).deposit(pId, liquidity);
        } else {
            IMasterChefV2(masterChef).deposit(pId, liquidity, address(this));
        }
    }

    function getPoolPairAddressForTokens() public view returns (address) {
        return
            IUniswapV2Factory(sushiFactory).getPair(
                address(tokenA),
                address(tokenB)
            );
    }

    // Owner can withdraw any remaining tokens from the contract
    function withdrawTokens(
        address tokenAddress,
        uint256 amount
    ) external OnlyOwner {
        IERC20(tokenAddress).transfer(owner, amount);
    }

    function CheckAllowance(IERC20 _Token) internal view returns(uint) {
        return IERC20(_Token).allowance(address(this), address(sushiRouter));
    }

    function CheckBalance(IERC20 _Token) internal view returns(uint) {
        return IERC20(_Token).balanceOf(address(this));
    }
    
}
