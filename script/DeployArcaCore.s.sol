//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {Script} from "openzeppelin-contracts/lib/forge-std/src/Script.sol";
import {ArcaCore} from "../src/ArcaCore.sol";

contract DeployArcaCore is Script {
    ArcaCore arca;
    uint8 constant DEFAULT_STRENGTH = 50;
    uint8 constant DEFAULT_AGILITY = 50;
    uint8 constant DEFAULT_INTELLIGENCE = 50;
    uint8 constant DEFAULT_WILLPOWER = 50;
    uint8 constant DEFAULT_MANIPULATION = 50;
    uint8 constant DEFAULT_INTIMIDATION = 50;
    uint8 constant DEFAULT_STEALTH = 50;
    uint8 constant DEFAULT_PERCEPTION = 50;
    int8 constant DEFAULT_MORALITY = 0;
    int8 constant DEFAULT_REPUTATION = 0;
    uint16 constant DEFAULT_WEALTH = 1000;

    address arkaToken = 0xC129124eA2Fd4D63C1Fc64059456D8f231eBbed1;

    function run() public {
        vm.startBroadcast();
        arca = new ArcaCore(
            DEFAULT_STRENGTH,
            DEFAULT_AGILITY,
            DEFAULT_INTELLIGENCE,
            DEFAULT_WILLPOWER,
            DEFAULT_MANIPULATION,
            DEFAULT_INTIMIDATION,
            DEFAULT_STEALTH,
            DEFAULT_PERCEPTION,
            DEFAULT_MORALITY,
            DEFAULT_REPUTATION,
            DEFAULT_WEALTH,
            arkaToken
        );
        vm.stopBroadcast();
    }
}
