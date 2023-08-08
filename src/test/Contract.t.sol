// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.19;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC20_UniV2} from "../Contract.sol";

interface IUniswapV2Router02 {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
    function WETH() external pure returns (address);
}

contract ContractTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);
    address immutable FORGE_DEPLOYER = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
    address immutable V2_ROUTER = 0xfCD3842f85ed87ba2889b4D35893403796e67FF1;
    Utilities internal utils;
    IUniswapV2Router02 internal uniswapV2Router;
    ERC20_UniV2 internal erc20_univ2;
    address payable[] internal users;
    //address[] public path;

    function setUp() public {
        utils = new Utilities();
        uniswapV2Router = IUniswapV2Router02(V2_ROUTER);
        users = utils.createUsers(5);

        erc20_univ2 = new ERC20_UniV2(address(549));
        vm.deal(FORGE_DEPLOYER, 100 ether);
    }

    function depositToContract() public {
        erc20_univ2.deposit{value: 10 ether}();
        assertGt(address(erc20_univ2).balance, 0);
    }

    function tryAddliquidity() public {
        depositToContract();
        erc20_univ2._addLiquidity();
    }

    function testSwapMaxWorkings() public {
        tryAddliquidity();
        address payable alice = users[0];
        address payable bob = users[1];
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.prank(alice);
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(erc20_univ2);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: 0.01 ether}(0, path, alice, 0);
        assertGt(erc20_univ2.balanceOf(alice), 0);
        vm.prank(alice);
        vm.expectRevert(abi.encodePacked("ERC20: transfer amount exceeds balance or max wallet"));
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: 0.1 ether}(0, path, alice, 0);
        erc20_univ2.setMax(15);
        vm.prank(bob);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: 0.1 ether}(0, path, alice, 0);
    }
}
