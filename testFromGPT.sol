// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniswapV3LiquidityProvision {
    INonfungiblePositionManager public positionManager;

    constructor(address _positionManager) {
        positionManager = INonfungiblePositionManager(_positionManager);
    }

    function provideLiquidity(
        address poolAddress,
        uint256 amountToken0,
        uint256 amountToken1,
        uint256 desiredWidth
    ) external {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
        
        // Получение токенов из пула
        address token0 = pool.token0();
        address token1 = pool.token1();

        // Перевод токенов на контракт
        IERC20(token0).transferFrom(msg.sender, address(this), amountToken0);
        IERC20(token1).transferFrom(msg.sender, address(this), amountToken1);

        // Одобрение для positionManager
        IERC20(token0).approve(address(positionManager), amountToken0);
        IERC20(token1).approve(address(positionManager), amountToken1);

        // Получаем цены из пулла
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
        uint256 lowerPrice = uint256(sqrtPriceX96) ** 2 >> (96 * 2);
        uint256 upperPrice = lowerPrice + (lowerPrice * desiredWidth / (10000 - desiredWidth));

        // Создаем позицию
        INonfungiblePositionManager.MintParams memory params =
            INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: pool.fee(),
                tickLower: int24(lowerPrice >> 96),
                tickUpper: int24(upperPrice >> 96),
                amount0Desired: amountToken0,
                amount1Desired: amountToken1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: msg.sender,
                deadline: block.timestamp + 60
            });

        // Создаем в Uniswap позицию
        positionManager.mint(params);
    }
}
