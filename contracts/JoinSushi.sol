// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SushiSwap/IMasterChef.sol";
import "./SushiSwap/IMasterChefV2.sol";
import "./UniSwap/IUniswapV2Factory.sol";
import "./UniSwap/IUniswapV2Router01.sol";

/// @title SushiSwapLiquidityInteract - A smart contract for interacting with SushiSwap for liquidity provision.
/// @notice This contract allows the owner to provide liquidity for two ERC20 tokens on SushiSwap and deposit the LP tokens into MasterChef.
contract SushiSwapLiquidityInteract {
    address public owner;
    IUniswapV2Router01 public sushiRouter;
    IUniswapV2Factory public sushiFactory;
    IERC20 public tokenA; // Token you want to provide liquidity for
    IERC20 public tokenB; // Token you want to pair with tokenA
    address public masterChef; // Address of MasterChefV1 or MasterChefV2
    bool public isMasterChefV1; // Is the target MasterChef contract MasterChefV1 or MasterChefV2

    event JoinLiquidityEvent(uint256 liquidity, uint256 amountA, uint256 amountB);

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

    /// @notice Allows the owner to provide liquidity for two tokens on SushiSwap and deposit the LP tokens into MasterChef.
    /// @param _amountA The amount of tokenA to provide for liquidity.
    /// @param _amountB The amount of tokenB to provide for liquidity.
    /// @param _pid The pool ID in MasterChef where the LP tokens will be deposited.
    function JoinLiquidity(uint256 _amountA, uint256 _amountB, uint _pid) public OnlyOwner {
        require(_amountA > 0, "Invalid TokenA Supply");
        require(_amountB > 0, "Invalid TokenB Supply");
        require(CheckBalance(tokenA) >= _amountA, "Insuficient Balance TokenA");
        require(CheckBalance(tokenB) >= _amountB, "Insuficient Balance TokenB");

        approveSushiRouterToUseTokens(_amountA, _amountB);

        // check allowance
        require(CheckAllowance(tokenA) >= _amountA, "Insuficient Allowance A");
        require(CheckAllowance(tokenB) >= _amountB, "Insuficient Allowance B");

        uint liquidity;
        (_amountA, _amountB, liquidity) = provideLiquidity(_amountA, _amountB);

        approveMasterChef(liquidity);
        depositLP(_pid, liquidity);

        // emit Event
        emit JoinLiquidityEvent(liquidity, _amountA, _amountB);
    }

    /// @notice Approves SushiSwap Router to spend tokens on behalf of the contract.
    /// @param _amountA The amount of tokenA to approve for spending.
    /// @param _amountB The amount of tokenB to approve for spending.
    function approveSushiRouterToUseTokens(uint256 _amountA, uint256 _amountB) private OnlyOwner {
        IERC20(tokenA).approve(address(sushiRouter), _amountA);
        IERC20(tokenB).approve(address(sushiRouter), _amountB);
    }

    /// @notice Provides liquidity on SushiSwap by swapping tokenA and tokenB for LP tokens.
    /// @param amountA The amount of tokenA to provide for liquidity.
    /// @param amountB The amount of tokenB to provide for liquidity.
    /// @return pAmountA The actual amount of tokenA provided for liquidity.
    /// @return pAmountB The actual amount of tokenB provided for liquidity.
    /// @return liquidity The amount of LP tokens obtained from providing liquidity.
    function provideLiquidity(
        uint256 amountA,
        uint256 amountB
    ) private OnlyOwner returns (uint, uint, uint) {
        uint256 valueA = sushiRouter.quote(amountB, amountB, amountA);
        uint256 valueB = sushiRouter.quote(amountA, amountA, amountB);

        (uint pAmountA, uint pAmountB, uint liquidity) = sushiRouter.addLiquidity(
            address(tokenA),
            address(tokenB),
            valueA,
            valueB,
            1,
            1,
            address(this),
            block.timestamp + 1000 * 60 * 5
        );
        return (pAmountA, pAmountB, liquidity);
    }

    /// @notice Approves MasterChef to spend LP tokens on behalf of the contract.
    /// @param amountLP The amount of LP tokens to approve for spending.
    function approveMasterChef(uint256 amountLP) private OnlyOwner {
        address addressPoolAB = getPoolPairAddressForTokens();
        IERC20(addressPoolAB).approve(address(masterChef), amountLP);
    }

    /// @notice Deposits LP tokens into MasterChef based on the specified pool ID.
    /// @param _pid The pool ID in MasterChef where the LP tokens will be deposited.
    /// @param liquidity The amount of LP tokens to deposit.
    function depositLP(uint _pid, uint256 liquidity) private OnlyOwner {
        if (isMasterChefV1) {
            IMasterChef(masterChef).deposit(_pid, liquidity);
        } else {
            IMasterChefV2(masterChef).deposit(_pid, liquidity, address(this));
        }
    }

    /// @notice Retrieves the address of the SushiSwap pair for the specified token pair (tokenA and tokenB).
    /// @return The address of the SushiSwap pair for the specified token pair.
    function getPoolPairAddressForTokens() public view returns (address) {
        return IUniswapV2Factory(sushiFactory).getPair(address(tokenA), address(tokenB));
    }

    /// @notice Allows the owner to withdraw any remaining tokens from the contract.
    /// @param tokenAddress The address of the token to be withdrawn.
    /// @param amount The amount of tokens to be withdrawn.
    function withdrawTokens(address tokenAddress, uint256 amount) external OnlyOwner {
        IERC20(tokenAddress).transfer(owner, amount);
    }

    /// @notice Checks the allowance of a specific token for the SushiSwap Router contract.
    /// @param _Token The token for which to check the allowance.
    /// @return The current allowance for the specified token.
    function CheckAllowance(IERC20 _Token) internal view returns (uint) {
        return IERC20(_Token).allowance(address(this), address(sushiRouter));
    }

    /// @notice Checks the balance of a specific token held by the contract.
    /// @param _Token The token for which to check the balance.
    /// @return The current balance of the specified token held by the contract.
    function CheckBalance(IERC20 _Token) internal view returns (uint) {
        return IERC20(_Token).balanceOf(address(this));
    }
}
