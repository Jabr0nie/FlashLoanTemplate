// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import {TokenHelper, IERC20} from "./libraries/TokenHelper.sol";
import {ILBRouter} from "./interfaces/ILBRouter.sol";



interface ILBTokenNFT {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function approveForAll(address spender, bool approved) external;
}

interface IRewarder {
    function claim(address user, uint256[] calldata ids) external;
    }

    interface IMOESwapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    }

contract MMLBTrader{

    //https://docs.lfj.gg/guides/add-remove-liquidity

    using TokenHelper for IERC20;
    using JoeLibrary for uint256;
    using PackedUint128Math for bytes32;

address public  admin;


    constructor(
) {
        admin = msg.sender;
    }


uint256 CurrentDepositID;
address LBrouter = 0x013e138EF6008ae5FDFDE29700e3f2Bc61d21E3a;
address Moe = 0x4515A45337F461A11Ff0FE8aBF3c606AE5dC00c9; 
address router = 0xeaEE7EE68874218c3558b40063c42B82D3E7232a;
uint256 binsAmount;
uint256 BinHolder;
address public tokenX = 0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a; //tokenX aUSD;
address public tokenY = 0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8;





function transferToAdmin(address Token) public payable {
    uint256 value = IERC20(Token).balanceOf(address(this));
    address to = 0x0B9BC785fd2Bea7bf9CB81065cfAbA2fC5d0286B;
    IERC20(Token).transfer(to, value);
}



//Swap directly with MM
  function Trade() external payable {
        
        uint256 amountIn = IERC20(tokenY).balanceOf(address(this));
        uint128 amountOut = 0;
        IERC20(tokenY).approve(LBrouter, amountIn); //Approve Spending

        IERC20[] memory tokenPath = new IERC20[](2);
        tokenPath[0] = IERC20(tokenY);
        tokenPath[1] = IERC20(tokenX);

        uint256[] memory pairBinSteps = new uint256[](1); // pairBinSteps[i] refers to the bin step for the market (x, y) where tokenPath[i] = x and tokenPath[i+1] = y
        pairBinSteps[0] = 10;

        ILBRouter.Version[] memory versions = new ILBRouter.Version[](1);
        versions[0] = ILBRouter.Version.V2_2; // add the version of the Dex to perform the swap on

        ILBRouter.Path memory path; // instanciate and populate the path to perform the swap.
        path.pairBinSteps = pairBinSteps;
        path.versions = versions;
        path.tokenPath = tokenPath;

    
        ILBRouter(LBrouter).swapExactTokensForTokens(amountIn, amountOut, path, address(this), block.timestamp + 1);
  }



}




