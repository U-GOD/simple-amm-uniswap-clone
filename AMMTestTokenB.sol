// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import ERC20 and Ownable from OpenZeppelin
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title TestToken
/// @notice Simple mintable ERC-20 token for testing AMM
contract AMMTestTokenB is ERC20, Ownable {
    /// @notice Constructor sets name, symbol, and initial supply
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    /// @notice Allows the owner to mint tokens to any address
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
