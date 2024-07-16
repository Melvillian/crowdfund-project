// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Project} from "../src/Project.sol";
import {TestProject} from "../test/TestProject.sol";
import {ProjectFactory} from "../src/ProjectFactory.sol";
import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";

contract ProjectTest is Test, ERC721TokenReceiver {
    TestProject public proj;
    string public constant TOKEN_NAME = "Test Token";
    string public constant TOKEN_SYMBOL = "TST";

    function setUp() public {
        proj = new TestProject(TOKEN_NAME, TOKEN_SYMBOL, 10 ether, address(this));
        targetSender(address(this));

        FuzzSelector memory fuzzSelector = FuzzSelector({addr: address(proj), selectors: new bytes4[](1)});
        fuzzSelector.selectors[0] = Project.claimNfts.selector;
        targetSelector(fuzzSelector);

        fuzzSelector = FuzzSelector({addr: address(proj), selectors: new bytes4[](1)});
        fuzzSelector.selectors[0] = Project.contribute.selector;
        targetSelector(fuzzSelector);
    }

    function invariant_num_nfts_claimable_and_held_by_user_always_matches_nfts_minted() public {
        assertEq(
            proj.summedBalances(address(this)) / 1 ether, proj.balanceOf(address(this)) + proj.nftsOwed(address(this))
        );
    }

    fallback() external payable {}
}
