// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC20Token.sol";
import "./library/Math.sol";
import "./library/UQ112x112.sol";

interface IERC20 {
    function balanceOf(address) external returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

error InsufficientLiquidityMinted();
error InsufficientLiquidityBurned();
error TransferFailed();
error InsufficientOutputAmount();
error InsufficientLiquidity();
error InvalidK();

error BalanceOverflow();

contract ZUniswapV2Pair is ERC20Token {
    using UQ112x112 for uint224;
    uint256 constant MINIMUM_LIQUIDITY = 1000;
    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;

    uint32  private blockTimestampLast;

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1);
    event Sync(uint256 reserve0, uint256 reserve1);
     event Swap(
        address indexed sender,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

    constructor(
        address _token0,
        address _token1
    ) ERC20Token("ZuniswapV2 pair", "ZUNIV2") {
        token0 = _token0;
        token1 = _token1;
    }

    // caller have been transfer token0 and token1 to the contract before call mint
    function mint() external {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

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
        _update(balance0, balance1,_reserve0,_reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    //caller transfer liquidity(LP Token) to the contract before call burn
    function burn(address to) external returns(uint256 amount0,uint256 amount1) {
         (uint112 _reserve0, uint112 _reserve1,) = getReserves();
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
        _update(balance0, balance1,_reserve0,_reserve1);

        emit Burn(to, amount0, amount1);
    }

    function swap(uint amount0Out,uint amount1Out,address to) external lock {

        if(amount0out == 0 && amount1out == 0) {
            revert InsufficientOutputAmount();
        }

        (uint112 reserve0,uint112 reserve1,) = getReserves();
        if(amount0Out > reserve0 || amount1Out > reserve1) {
            revert InsufficientLiquidity();
        }

        // 计算swap后，池子内两token的余额
        uint balance0 = IERC20(token0).balanceOf(address(this)) - amount0Out;
        uint balance1 = IERC20(token1).balanceOf(address(this)) - amount1Out;

        if(balance0 * balance1 < uint256(reserve0) * uint256(reserve1)) {
            revert InvalidK();
        }

        // 更新reserve
        _update(balance0, balance1,reserve0,reserve1);

        // 转移代币
        if(amount0Out > 0) {
            IERC20(token0).transfer(to, amount0Out);
        }
        if(amount1Out > 0) {
            IERC20(token1).transfer(to, amount1Out);
        }

        emit Swap(msg.sender,amount0Out,amount1Out,to);

    }

    // update reserves
    function _update(uint256 balance0, 
                     uint256 balance1,
                     uint112 _reserve0,
                     uint112 _reserve1) private {
        
        if(balance0 > type(uint112).max || balance1 > type(uint112).max) {
            revert BalanceOverflow();
        }
        uint32 blockTimestamp = uint32(block.timestamp);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        if(timeElapsed > 0 && _reserve0 > 0 && _reserve1 > 0) {
            price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        blockTimestampLast = blockTimestamp;

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        emit Sync(reserve0, reserve1);
    }

    function getReserves() public view returns (uint112, uint112,uint32) {
        return (reserve0, reserve1, blockTimestampLast);
    }

    
}
