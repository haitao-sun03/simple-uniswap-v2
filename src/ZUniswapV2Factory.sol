// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {ZUniswapV2Pair} from "./ZUniswapV2Pair.sol";

contract ZUniswapV2Factory {

    mapping(address => mapping(address => address)) public pairs;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(pairs[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient

        address pair = address(new ZUniswapV2Pair{salt:keccak256(abi.encodePacked(token0, token1))}());
        pairs[token0][token1] = pair;
        pairs[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}