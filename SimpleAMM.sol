// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SimpleAMM
/// @notice Minimal Uniswap V2 Pair clone with x*y=k formula
contract SimpleAMM {
    // Addresses of the two ERC20 tokens in the pair
    address public immutable tokenA;
    address public immutable tokenB;

    // Reserves of token A and token B in the pool
    uint256 public reserveA;
    uint256 public reserveB;

    // Total supply of LP tokens
    uint256 public totalSupply;

    // Mapping: address => LP balance
    mapping(address => uint256) public balanceOf;

    // Events for logging
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpMinted);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpBurned);
    event Swapped(address indexed trader, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

    /// @notice Constructor sets the token pair addresses
    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token addresses");
        require(_tokenA != _tokenB, "Tokens must differ");

        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    /// @dev Safe transferFrom to pull tokens into the contract
    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                bytes4(keccak256("transferFrom(address,address,uint256)")),
                from,
                to,
                amount
            )
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "transferFrom failed");
    }

    /// @dev Safe transfer to send tokens out of the contract
    function _safeTransfer(address token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                bytes4(keccak256("transfer(address,uint256)")),
                to,
                amount
            )
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "transfer failed");
    }

    /**
     * @notice Add liquidity to the pool
     * @param amount0 Amount of token0 to deposit
     * @param amount1 Amount of token1 to deposit
     * @return liquidity Amount of LP tokens minted to the provider
     */
    function addLiquidity(uint256 amount0, uint256 amount1) external returns (uint256 liquidity) {
        require(amount0 > 0 && amount1 > 0, "Amounts must be >0");

        // Transfer tokens from sender to contract
        _safeTransferFrom(tokenA, msg.sender, address(this), amount0);
        _safeTransferFrom(tokenB, msg.sender, address(this), amount1);

        // Get updated balances
        uint256 balance0 = IERC20(tokenA).balanceOf(address(this));
        uint256 balance1 = IERC20(tokenB).balanceOf(address(this));

        // Calculate how much liquidity to mint
        if (totalSupply == 0) {
            // First liquidity provider sets initial liquidity
            liquidity = sqrt(amount0 * amount1);
        } else {
            // Subsequent providers mint proportionally
            liquidity = min(
                (amount0 * totalSupply) / reserveA,
                (amount1 * totalSupply) / reserveB
            );
        }
        require(liquidity > 0, "Insufficient liquidity minted");

        // Mint LP tokens to sender
        balanceOf[msg.sender] += liquidity;
        totalSupply += liquidity;

        // Update reserves
        reserveA = balance0;
        reserveB = balance1;

        emit LiquidityAdded(msg.sender, amount0, amount1, liquidity);
    }

    /**
     * @notice Returns the smaller of two numbers
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    /**
     * @notice Computes integer square root of a number
     */
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /**
     * @notice Swap tokens while preserving the constant product invariant
     * @param amountIn Amount of input token sent
     * @param tokenIn Address of the input token
     */
    function swap(uint256 amountIn, address tokenIn) external {
        require(amountIn > 0, "Amount must be > 0");
        require(tokenIn == tokenA || tokenIn == tokenB, "Invalid tokenIn");

        // Determine which token is input and which is output
        (IERC20 inToken, IERC20 outToken, uint256 reserveIn, uint256 reserveOut) = 
            tokenIn == tokenA 
                ? (IERC20(tokenA), IERC20(tokenB), reserveA, reserveB)
                : (IERC20(tokenB), IERC20(tokenA), reserveB, reserveA);

        // Transfer input tokens from sender
        bool received = inToken.transferFrom(msg.sender, address(this), amountIn);
        require(received, "Transfer failed");

        // Calculate output amount using constant product formula with 0.3% fee
        uint256 amountInWithFee = amountIn * 997; // 0.3% fee
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        uint256 amountOut = numerator / denominator;

        require(amountOut > 0, "Insufficient output amount");
        require(amountOut < reserveOut, "Not enough liquidity");

        // Transfer output tokens to sender
        bool sent = outToken.transfer(msg.sender, amountOut);
        require(sent, "Transfer failed");

        // Update reserves
        if (tokenIn == tokenA) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }
    }

    /**
     * @notice Remove liquidity and burn LP tokens
     * @param liquidity Amount of LP tokens to burn
     */
    function removeLiquidity(uint256 liquidity) external {
        require(liquidity > 0, "Amount must be > 0");
        require(totalSupply > 0, "No liquidity");

        // Calculate amounts owed
        uint256 amountA = (liquidity * reserveA) / totalSupply;
        uint256 amountB = (liquidity * reserveB) / totalSupply;

        require(amountA > 0 && amountB > 0, "Insufficient amounts");

        // Update reserves
        reserveA -= amountA;
        reserveB -= amountB;

        // Burn LP tokens
        balanceOf[msg.sender] -= liquidity;

        // Transfer tokens back to liquidity provider
        _safeTransfer(tokenA, msg.sender, amountA);
        _safeTransfer(tokenB, msg.sender, amountB);
    }
}
