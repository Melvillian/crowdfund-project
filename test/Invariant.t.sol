// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";

import {Project} from "../src/Project.sol";
import {TestProjectHandler} from "../test/TestProjectHandler.sol";
import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";

contract ProjectTest is Test {
    TestProjectHandler public projHandler;
    Project public proj;
    string public constant TOKEN_NAME = "Test Token";
    string public constant TOKEN_SYMBOL = "TST";

    function setUp() public {
        proj = new Project(TOKEN_NAME, TOKEN_SYMBOL, 10 ether, address(this));
        projHandler = new TestProjectHandler(proj);

        targetContract(address(projHandler));

        // Fund test handler with ETH
        vm.deal(address(projHandler), 100000 ether);

        FuzzSelector memory fuzzSelector = FuzzSelector({addr: address(projHandler), selectors: new bytes4[](1)});
        fuzzSelector.selectors[0] = TestProjectHandler.claimNfts.selector;
        targetSelector(fuzzSelector);

        fuzzSelector = FuzzSelector({addr: address(projHandler), selectors: new bytes4[](1)});
        fuzzSelector.selectors[0] = TestProjectHandler.contribute.selector;
        targetSelector(fuzzSelector);
    }

    function invariant_num_nfts_claimable_and_held_by_user_always_matches_nfts_minted() public {
        assertEq(
            projHandler.summedBalances(address(projHandler)) / 1 ether,
            proj.balanceOf(address(projHandler)) + proj.nftsOwed(address(projHandler))
        );
    }
}
