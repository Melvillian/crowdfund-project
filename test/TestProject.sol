// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Project} from "../src/Project.sol";
import "forge-std/console.sol";

/**
 * @title TestProject
 * @dev A contract that adds some ghost variables to allow for invariant testing
 */
contract TestProject is Project {
    // this value does not decrease when withdrawEth is called, which allows us
    // to efficiently calculate the number of nfts a user is due even after they
    // are claimed
    mapping(address => uint256) public summedBalances;

    constructor(string memory _name, string memory _symbol, uint256 _goal, address _creator)
        Project(_name, _symbol, _goal, _creator)
    {}

    function contribute() public payable override {
        console.log("msg.value", msg.value);
        super.contribute();
        summedBalances[msg.sender] += msg.value;
    }
}
