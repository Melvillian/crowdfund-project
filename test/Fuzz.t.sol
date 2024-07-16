// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Project} from "../src/Project.sol";
import {ProjectFactory} from "../src/ProjectFactory.sol";
import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";

contract ProjectTest is Test, ERC721TokenReceiver {
    ProjectFactory public factory;
    Project public proj;
    string public constant TOKEN_NAME = "Test Token";
    string public constant TOKEN_SYMBOL = "TST";

    function setUp() public {
        factory = new ProjectFactory();
        proj = factory.create(10 ether, TOKEN_NAME, TOKEN_SYMBOL);
    }

    function test_fuzz_can_contribute_funds_as_expected(uint256 amount) public {
        amount = bound(amount, proj.MIN_CONTRIBUTION(), address(this).balance);
        Project projo = factory.create(amount, TOKEN_NAME, TOKEN_SYMBOL);

        projo.contribute{value: amount}();

        assertEq(projo.balances(address(this)), amount);
    }

    function test_fuzz_can_withdraw_funds_as_expected(
        uint256 goalAmount,
        uint256 contributeAmount,
        uint256 withdrawAmount
    ) public {
        vm.assume(goalAmount > proj.MIN_CONTRIBUTION());
        goalAmount = bound(goalAmount, proj.MIN_CONTRIBUTION(), address(this).balance);
        contributeAmount = bound(contributeAmount, proj.MIN_CONTRIBUTION(), goalAmount - 1);
        withdrawAmount = bound(withdrawAmount, 0, contributeAmount);

        Project projo = factory.create(goalAmount, TOKEN_NAME, TOKEN_SYMBOL);

        projo.contribute{value: contributeAmount}();

        uint256 preBalance = address(this).balance;

        vm.warp(projo.endDate() + 1);

        projo.withdrawEth(withdrawAmount);

        assertEq(projo.balances(address(this)), contributeAmount - withdrawAmount);
        assertEq(address(this).balance, preBalance + withdrawAmount);
    }

    fallback() external payable {}

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
