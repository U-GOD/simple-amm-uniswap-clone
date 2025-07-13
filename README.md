# Simple AMM - Uniswap v2 Pair Clone

This project is a **minimal Automated Market Maker (AMM)** smart contract inspired by Uniswap v2. It allows users to:

- Provide liquidity for a pair of ERC-20 tokens.
- Swap tokens against the liquidity pool.
- Remove liquidity and reclaim tokens.

It uses the **x * y = k** constant product formula and includes a 0.3% trading fee.

---

## 🛠 Features

✅ ERC-20 liquidity pools  
✅ Liquidity provision with LP token balances  
✅ Swaps with 0.3% fee  
✅ Liquidity removal  
✅ Minimal dependencies  

---

## 📄 Contracts

### `AMMTestTokenA.sol` and `AMMTestTokenB.sol`
Simple mintable ERC-20 tokens for testing the AMM.

### `SimpleAMM.sol`
The AMM contract implementing:
- `addLiquidity()` to deposit token pairs.
- `swap()` to trade one token for the other.
- `removeLiquidity()` to redeem LP shares.

---

## 🧪 How to Deploy and Test

1. **Deploy two ERC-20 tokens:**
   - `AMMTestTokenA` with an initial supply (e.g., 1 million tokens).
   - `AMMTestTokenB` with an initial supply.

2. **Deploy the SimpleAMM contract:**
   - Constructor parameters:
     - Address of Token A.
     - Address of Token B.

3. **Approve token transfers:**
   ```solidity
   tokenA.approve(simpleAMM.address, amount);
   tokenB.approve(simpleAMM.address, amount);
   ```

4. **Add liquidity:**
   ```solidity
   simpleAMM.addLiquidity(amountTokenA, amountTokenB);
   ```

5. **Swap tokens:**
   ```solidity
   simpleAMM.swap(amountIn, tokenAddress);
   ```

6. **Remove liquidity:**
   ```solidity
   simpleAMM.removeLiquidity(BalanceOf);
   ```

---

## 📚 Learn More

This project is for educational purposes to understand:
- Constant product AMMs.
- Liquidity provision mechanics.
- Simple swap fee logic.

For production-grade contracts, always use audited implementations like [Uniswap V2](https://github.com/Uniswap/v2-core).

---

## ✨ Author

Built step by step to learn Solidity DeFi patterns.
