# Join the SushiSwap Liquidity Mining Program

This project is to joining the SushiSwap liquidity mining program in a single transaction.

The smart contract is compatible with both MasterChefV1 and MasterChefV2, and it can work with any pair of tokens.

## Setup

1. `git clone https://github.com/rtomas/join-sushi.git`
2. `npm install`

## Test

1. You must get the free key from infura and add it to the .env file.
2. Run
   `npx hardhat test --network hardhat`

## Contract Structure

The contract 'JoinSushi.sol' is written in Solidity and consists of several key components:

-   `SushiSwapLiquidityInteract` contract: The main contract that facilitates the interaction with SushiSwap and MasterChef.
-   Interfaces: Imports interfaces for ERC20 tokens, SushiSwap MasterChef contracts (both V1 and V2), and Uniswap V2 contracts.
-   Events: Defines an event `JoinLiquidityEvent` to log information about the liquidity provision.

## Initialization

The contract is initialized with the following parameters:

-   `_sushiRouter`: Address of the Uniswap V2 Router01 contract for SushiSwap.
-   `_tokenA`: Address of the first ERC20 token for liquidity provision.
-   `_tokenB`: Address of the second ERC20 token to pair with `_tokenA`.
-   `_masterChef`: Address of the MasterChef contract (either V1 or V2).
-   `_isMasterChefV1`: Boolean indicating whether the target MasterChef contract is MasterChef V1 or V2.

## Functions

### `JoinLiquidity`

Allows the owner to provide liquidity for two tokens on SushiSwap and deposit the LP tokens into MasterChef.

Parameters:

-   `_amountA`: The amount of `tokenA` to provide for liquidity.
-   `_amountB`: The amount of `tokenB` to provide for liquidity.
-   `_pid`: The pool ID in MasterChef where the LP tokens will be deposited.

## How to start

You have to deploy the smart contract and after that transfer both amount of tokens to address of the contract.
Then you can call the `JoinLiquidity` function to start proving liquidity.
To call this function you would need to know the pid of the pair

## Future Improvements

-   Reduce gas transactions when calling `JoinLiquidity`.
-   Generate a deploy script.
-   Genarete more test.
    -   Only owner.
    -   Tokens but wrong pid.
    -   Wrong router.
