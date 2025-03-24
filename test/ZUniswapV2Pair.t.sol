// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ZUniswapV2Pair} from "../src/ZUniswapV2Pair.sol";
import {ERC20} from "../src/ERC20Token.sol";

contract ERC20Mintable is ERC20 {
    constructor(string memory _name,string memory _symbol) ERC20(_name,_symbol) {}

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}

contract CounterTest is Test {
    ZUniswapV2Pair public zUniswapV2Pair;
    ERC20Mintable token0;
    ERC20Mintable token1;

    function setUp() public {
        token0 = new ERC20Mintable("Token A","TKNA");
        token1 = new ERC20Mintable("Token B","TKNB");

        zUniswapV2Pair = new ZUniswapV2Pair(address(token0),address(token1));

        token0.mint(10 ether);
        token1.mint(10 ether);
    }

    function assertReserve(uint112 _reserve0,uint112 _reserve1) view private {
        (uint112 reserve0,uint112 reserve1)  = zUniswapV2Pair.getReserves();
        assertEq(reserve0 , _reserve0);
        assertEq(reserve1 , _reserve1);
    }

    function test_FirstMint() public {
        token0.transfer(address(zUniswapV2Pair), 1 ether);
        token1.transfer(address(zUniswapV2Pair), 1 ether);

        zUniswapV2Pair.mint();

        assertEq(zUniswapV2Pair.balanceOf(address(this)), 1 ether);
        assertEq(zUniswapV2Pair.totalSupply(), 1 ether);
        assertReserve(1 ether,1 ether);
    }

    

    function test_OtherMint() public {
        token0.transfer(address(zUniswapV2Pair), 1 ether);
        token1.transfer(address(zUniswapV2Pair), 1 ether);

        zUniswapV2Pair.mint();

        token0.transfer(address(zUniswapV2Pair), 1 ether);
        token1.transfer(address(zUniswapV2Pair), 5 ether);

        zUniswapV2Pair.mint();

        assertReserve(2 ether,6 ether);
        assertEq(zUniswapV2Pair.balanceOf(address(this)), 2 ether);
        assertEq(zUniswapV2Pair.totalSupply(), 2 ether);
        

    }


    function test_Burn() public {
        token0.transfer(address(zUniswapV2Pair), 2 ether);
        token1.transfer(address(zUniswapV2Pair), 2 ether);

        zUniswapV2Pair.mint();

        assertReserve(2 ether, 2 ether);
        assertEq(zUniswapV2Pair.balanceOf(address(this)), 2 ether);
        assertEq(zUniswapV2Pair.totalSupply(), 2 ether);
        assertEq(zUniswapV2Pair.balanceOf(address(zUniswapV2Pair)), 0 ether);

        zUniswapV2Pair.transfer(address(zUniswapV2Pair), 1 ether);
        zUniswapV2Pair.burn(address(this));

        assertReserve(1 ether, 1 ether);
        assertEq(zUniswapV2Pair.balanceOf(address(this)), 1 ether);
        assertEq(token0.balanceOf(address(this)), 9 ether);
        assertEq(token1.balanceOf(address(this)), 9 ether);
        

        zUniswapV2Pair.transfer(address(zUniswapV2Pair), 1 ether);
        zUniswapV2Pair.burn(address(this));

        assertReserve(0 ether, 0 ether);
        assertEq(zUniswapV2Pair.balanceOf(address(this)), 0 ether);
        assertEq(token0.balanceOf(address(this)), 10 ether);
        assertEq(token1.balanceOf(address(this)), 10 ether);
    }
}
