// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Project} from "../src/Project.sol";
import {ProjectFactory} from "../src/ProjectFactory.sol";
import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";

contract ProjectTest is Test, ERC721TokenReceiver {
    ProjectFactory public factory;
    string public constant TOKEN_NAME = "Test Token";
    string public constant TOKEN_SYMBOL = "TST";

    function setUp() public {
        factory = new ProjectFactory();
    }

    function test_can_create_project() public {
        vm.expectEmit(true, false, false, true);

        emit Project.ProjectCreated(address(this), 10 ether);

        Project proj = factory.create(10 ether, TOKEN_NAME, TOKEN_SYMBOL);

        assertEq(proj.goal(), 10 ether);
        assertEq(proj.name(), TOKEN_NAME);
        assertEq(proj.symbol(), TOKEN_SYMBOL);
        assertEq(address(this), proj.creator());
    }

    function test_goal_too_low() public {
        vm.expectRevert(abi.encodeWithSelector(Project.GoalTooLow.selector, 0.001 ether));

        factory.create(0.001 ether, TOKEN_NAME, TOKEN_SYMBOL);
    }

    function test_successful_contribution() public {
        Project proj = factory.create(10 ether, TOKEN_NAME, TOKEN_SYMBOL);

        vm.expectEmit(true, false, false, true);
        emit Project.Contributed(address(this), 1 ether, 1);
        proj.contribute{value: 1 ether}();

        assertEq(proj.balances(address(this)), 1 ether);
        assertEq(proj.nftsOwed(address(this)), 1);
        assertEq(proj.nftsMinted(), 0);
    }

    function test_successful_contribution_with_greater_than_1_ether() public {
        Project proj = factory.create(10 ether, TOKEN_NAME, TOKEN_SYMBOL);

        vm.expectEmit(true, false, false, true);
        emit Project.Contributed(address(this), 3 ether, 3);
        proj.contribute{value: 3 ether}();

        assertEq(proj.balances(address(this)), 3 ether);
        assertEq(proj.nftsOwed(address(this)), 3);
        assertEq(proj.nftsMinted(), 0);
    }

    function test_successful_contribution_with_non_integer_contribution() public {
        Project proj = factory.create(10 ether, TOKEN_NAME, TOKEN_SYMBOL);

        vm.expectEmit(true, false, false, true);
        emit Project.Contributed(address(this), 3.5 ether, 3);
        proj.contribute{value: 3.5 ether}();

        assertEq(proj.balances(address(this)), 3.5 ether);
        assertEq(proj.nftsOwed(address(this)), 3);
        assertEq(proj.nftsMinted(), 0);
    }

    function test_successful_multi_contribution_no_nft_increase() public {
        Project proj = factory.create(10 ether, TOKEN_NAME, TOKEN_SYMBOL);

        vm.expectEmit(true, false, false, true);
        emit Project.Contributed(address(this), 3.5 ether, 3);
        proj.contribute{value: 3.5 ether}();

        vm.expectEmit(true, false, false, true);
        emit Project.Contributed(address(this), 0.4 ether, 0);
        proj.contribute{value: 0.4 ether}();

        assertEq(proj.balances(address(this)), 3.9 ether);
        assertEq(proj.nftsOwed(address(this)), 3);
        assertEq(proj.nftsMinted(), 0);
    }

    function test_successful_multi_contribution_with_nft_increase() public {
        Project proj = factory.create(10 ether, TOKEN_NAME, TOKEN_SYMBOL);

        vm.expectEmit(true, false, false, true);
        emit Project.Contributed(address(this), 3.5 ether, 3);
        proj.contribute{value: 3.5 ether}();

        vm.expectEmit(true, false, false, true);
        emit Project.Contributed(address(this), 0.6 ether, 1);
        proj.contribute{value: 0.6 ether}();

        assertEq(proj.balances(address(this)), 4.1 ether);
        assertEq(proj.nftsOwed(address(this)), 4);
        assertEq(proj.nftsMinted(), 0);
        assertEq(proj.isCancelled(), false);
        assertEq(proj.isFunded(), false);

        assertEq(proj.balances(address(1)), 0 ether);
        assertEq(proj.nftsOwed(address(1)), 0);
    }

    function test_successful_funding_of_project() public {
        Project proj = factory.create(5 ether, TOKEN_NAME, TOKEN_SYMBOL);

        vm.expectEmit(true, false, false, true);
        emit Project.GoalReached(5 ether);
        proj.contribute{value: 5 ether}();

        assertEq(proj.isFunded(), true);
        assertEq(proj.isCancelled(), false);
    }

    function test_cannot_contribute_to_already_funded_project() public {
        Project proj = factory.create(5 ether, TOKEN_NAME, TOKEN_SYMBOL);

        proj.contribute{value: 5 ether}();

        assertEq(proj.isFunded(), true);
        assertEq(proj.isCancelled(), false);

        vm.expectRevert(abi.encodeWithSelector(Project.ProjectAlreadyFunded.selector));
        proj.contribute{value: 0.001 ether}();
    }

    function test_contribution_too_low() public {
        Project proj = factory.create(10 ether, TOKEN_NAME, TOKEN_SYMBOL);

        vm.expectRevert(abi.encodeWithSelector(Project.ContributionTooLow.selector, 0.001 ether));
        proj.contribute{value: 0.001 ether}();
    }

    function test_cannot_contribute_after_project_failure() public {
        Project proj = factory.create(10 ether, TOKEN_NAME, TOKEN_SYMBOL);

        vm.warp(proj.endDate() + 1);

        vm.expectRevert(abi.encodeWithSelector(Project.ProjectPastEnddate.selector, proj.endDate(), block.timestamp));
        proj.contribute{value: 1 ether}();
    }

    function test_can_cancel() public {
        Project proj = factory.create(10 ether, TOKEN_NAME, TOKEN_SYMBOL);

        proj.cancelProject();

        assertEq(proj.isCancelled(), true);

        vm.expectRevert(abi.encodeWithSelector(Project.ProjectCancelled.selector));
        proj.cancelProject();
    }

    function test_cannot_cancel_after_project_failure() public {
        Project proj = factory.create(10 ether, TOKEN_NAME, TOKEN_SYMBOL);

        vm.warp(proj.endDate() + 1);

        vm.expectRevert(abi.encodeWithSelector(Project.ProjectPastEnddate.selector, proj.endDate(), block.timestamp));
        proj.cancelProject();

        assertEq(proj.isCancelled(), false);
    }

    function test_claim_1_nft() public {
        Project proj = factory.create(10 ether, TOKEN_NAME, TOKEN_SYMBOL);
        proj.contribute{value: 0.9 ether}();
        proj.contribute{value: 0.1 ether}();

        vm.expectEmit(true, false, false, true);
        emit Project.NftsClaimed(address(this), 1);
        proj.claimNfts();

        assertEq(proj.nftsMinted(), 1);
        assertEq(proj.balances(address(this)), 1 ether);
        assertEq(proj.nftsOwed(address(this)), 0);
        assertEq(proj.balanceOf(address(this)), 1);
    }

    function test_claim_multiple_nfts() public {
        Project proj = factory.create(10 ether, TOKEN_NAME, TOKEN_SYMBOL);
        proj.contribute{value: 1.9 ether}();
        proj.contribute{value: 0.1 ether}();

        vm.expectEmit(true, false, false, true);
        emit Project.NftsClaimed(address(this), 2);
        proj.claimNfts();

        assertEq(proj.nftsMinted(), 2);
        assertEq(proj.balances(address(this)), 2 ether);
        assertEq(proj.nftsOwed(address(this)), 0);
        assertEq(proj.balanceOf(address(this)), 2);
    }

    function test_claim_no_nft_to_claim() public {
        Project proj = factory.create(10 ether, TOKEN_NAME, TOKEN_SYMBOL);
        proj.contribute{value: 0.9 ether}();

        vm.expectRevert(abi.encodeWithSelector(Project.NoNftsToClaim.selector));
        proj.claimNfts();

        assertEq(proj.nftsMinted(), 0);
        assertEq(proj.balances(address(this)), 0.9 ether);
        assertEq(proj.nftsOwed(address(this)), 0);
    }

    function test_cannot_withdraw_before_project_failure() public {
        Project proj = factory.create(10 ether, TOKEN_NAME, TOKEN_SYMBOL);

        proj.contribute{value: 1 ether}();

        vm.expectRevert(abi.encodeWithSelector(Project.ProjectMustBeFailed.selector));
        proj.withdrawEth(1 ether);
    }

    function test_cannot_withdraw_if_project_goal_reached() public {
        Project proj = factory.create(10 ether, TOKEN_NAME, TOKEN_SYMBOL);

        proj.contribute{value: 10 ether}();

        vm.expectRevert(abi.encodeWithSelector(Project.ProjectMustBeFailed.selector));
        proj.withdrawEth(1 ether);
    }

    function test_can_withdraw_if_project_cancelled() public {
        Project proj = factory.create(10 ether, TOKEN_NAME, TOKEN_SYMBOL);

        proj.contribute{value: 1 ether}();
        proj.cancelProject();
        proj.withdrawEth(1 ether);
    }

    function test_can_withdraw_if_project_past_end_date() public {
        Project proj = factory.create(10 ether, TOKEN_NAME, TOKEN_SYMBOL);
        proj.contribute{value: 1 ether}();
        vm.warp(proj.endDate() + 1);
        proj.withdrawEth(1 ether);

        assertEq(proj.balances(address(this)), 0);
        assertEq(proj.nftsOwed(address(this)), 1);
        assertEq(proj.nftsMinted(), 0);
    }

    fallback() external payable {}
}
