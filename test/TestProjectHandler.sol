// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Project} from "../src/Project.sol";
import {Test, console} from "forge-std/Test.sol";
import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";

/**
 * @title TestProjectHandler
 * @dev A contract that adds some ghost variables to allow for invariant testing
 */
contract TestProjectHandler is Test, ERC721TokenReceiver {
    // this value does not decrease when withdrawEth is called, which allows us
    // to efficiently calculate the number of nfts a user is due even after they
    // are claimed
    mapping(address => uint256) public summedBalances;
    Project public project;

    constructor(Project _proj) {
        project = _proj;
    }

    function contribute(uint256 amount) public payable {
        amount = bound(amount, project.MIN_CONTRIBUTION(), 10 ether);
        project.contribute{value: amount}();
        summedBalances[address(this)] += amount;
    }

    function claimNfts() public {
        project.claimNfts();
    }
}
