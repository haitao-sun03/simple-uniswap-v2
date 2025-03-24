// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC20Token.sol";
import "./library/Math.sol";

interface IERC20 {
    function balanceOf(address) external returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

error InsufficientLiquidityMinted();
error InsufficientLiquidityBurned();
error TransferFailed();

contract ZUniswapV2Pair is ERC20Token {
    uint256 constant MINIMUM_LIQUIDITY = 1000;
    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1);
    event Sync(uint256 reserve0, uint256 reserve1);

    constructor(
        address _token0,
        address _token1
    ) ERC20Token("ZuniswapV2 pair", "ZUNIV2") {
        token0 = _token0;
        token1 = _token1;
    }

    // caller have been transfer token0 and token1 to the contract before call mint
    function mint() external {
        // 1 1
        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        // 2 2
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        // 1，1
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        uint256 liquidity;

        // 池子首次创建
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1);
            // _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(
                (totalSupply * amount0) / _reserve0,
                (totalSupply * amount1) / _reserve1
            );
        }

        if (liquidity <= 0) revert InsufficientLiquidityMinted();

        _mint(msg.sender, liquidity);
        _update(balance0, balance1);
        emit Mint(msg.sender, amount0, amount1);
    }

    //caller transfer liquidity(LP Token) to the contract before call burn
    function burn(address to) external returns(uint256 amount0,uint256 amount1) {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 liquidity =  balanceOf(address(this));
        uint256 totalSupply = totalSupply();

        amount0 = balance0 * liquidity / totalSupply;
        amount1 = balance1 * liquidity / totalSupply;

        _burn(address(this),liquidity);

        bool successToken0 = IERC20(token0).transfer(to, amount0);
        bool successToken1 = IERC20(token1).transfer(to, amount1);
        if (!successToken0 || !successToken1) {
            revert TransferFailed();
        }

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));
        _update(balance0, balance1);

        emit Burn(to, amount0, amount1);
    }

    // update reserves
    function _update(uint balance0, uint balance1) private {
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        emit Sync(reserve0, reserve1);
    }

    function getReserves() public view returns (uint112, uint112) {
        return (reserve0, reserve1);
    }

    
}
