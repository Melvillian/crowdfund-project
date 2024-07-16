// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ProjectFactory} from "../src/ProjectFactory.sol";

contract ProjectFactoryScript is Script {
    ProjectFactory public factory;

    function setUp() public {}

    function run() public {
        // vm.startBroadcast();
        // counter = new Counter();
        // vm.stopBroadcast();
    }
}
