// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Project} from "./Project.sol";

contract ProjectFactory {
    function create(uint256 goal, string memory name, string memory symbol) public returns (Project) {
        Project project = new Project(name, symbol, goal, msg.sender);
        return project;
    }
}
