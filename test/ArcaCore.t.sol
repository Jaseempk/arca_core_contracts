// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {ArcaCore} from "../src/ArcaCore.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract ArcaCoreTest is Test {
    ArcaCore arcaCore;
    MockERC20 arcaToken;

    // Test addresses
    address public ADMIN = makeAddr("admin");
    address public USER = makeAddr("user");
    address public AGENT_ADDR = makeAddr("agent");

    // Events to test
    event CityCreated(
        address creator,
        string name,
        uint32 maxPopulation,
        uint128 createdAt
    );
    event AgentCreated(
        address owner,
        string agentName,
        address agentAddy,
        string persona,
        uint256 balance,
        ArcaCore.AgentTraits defaultTraits,
        uint128 agentDob,
        uint16 reputationScore
    );
    event AgentKilled(address caller, address agentAddy, uint256 timestamp);

    // Default trait values
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

    function setUp() public {
        // Deploy mock token
        arcaToken = new MockERC20("Arca Token", "ARCA");

        // Deploy main contract with default traits
        vm.prank(ADMIN);
        arcaCore = new ArcaCore(
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
            0xC129124eA2Fd4D63C1Fc64059456D8f231eBbed1
        );

        // Setup roles
        vm.startPrank(ADMIN);
        arcaCore.grantRole(arcaCore.DEFAULT_ADMIN_ROLE(), ADMIN);
        vm.stopPrank();
    }

    // City Creation Tests
    function test_CreateCity() public {
        vm.startPrank(ADMIN);

        string memory cityName = "New York";
        uint128 treasury = 1000000;
        uint32 maxPop = 1000000;

        vm.expectEmit(true, true, true, true);
        emit CityCreated(ADMIN, cityName, maxPop, uint128(block.timestamp));

        arcaCore.createCity(cityName, treasury, maxPop);
        vm.stopPrank();
    }

    function testFail_CreateCity_NonAdmin() public {
        vm.prank(USER);
        arcaCore.createCity("Failed City", 1000, 1000);
    }

    function testFail_CreateCity_EmptyName() public {
        vm.prank(ADMIN);
        arcaCore.createCity("", 1000, 1000);
    }

    function testFail_CreateCity_ZeroPopulation() public {
        vm.prank(ADMIN);
        arcaCore.createCity("Test City", 1000, 0);
    }

    // Agent Creation Tests
    function test_CreateAgent() public {
        string memory agentName = "Agent Smith";
        uint16 repScore = 15;

        vm.startPrank(USER);
        arcaCore.createAgent(agentName, AGENT_ADDR, repScore);

        (
            string memory _agentName,
            address _owner,
            ,
            ,
            ,
            ,
            ,
            bool _isAlive,
            uint16 _reputationScore
        ) = arcaCore.addressToAgent(AGENT_ADDR);
        assertEq(_agentName, agentName);
        assertEq(_owner, USER);
        assertEq(_isAlive, true);
        assertEq(_reputationScore, repScore);
        vm.stopPrank();
    }

    function testFail_CreateAgent_DuplicateAgent() public {
        vm.startPrank(USER);

        arcaCore.createAgent("Agent Smith", AGENT_ADDR, 15);

        arcaCore.createAgent("Agent Smith 2", AGENT_ADDR, 15);
        vm.stopPrank();
    }

    function testFail_CreateAgent_EmptyName() public {
        vm.prank(USER);
        arcaCore.createAgent("", AGENT_ADDR, 15);
    }

    // Agent Killing Tests
    function test_KillAgent() public {
        // First create an agent
        vm.prank(USER);
        arcaCore.createAgent(
            "Dead Agent",
            AGENT_ADDR,
            10 // Below MIN_REPUTATION_SCORE
        );

        // Kill the agent
        vm.prank(ADMIN);
        vm.expectEmit(true, true, true, true);
        emit AgentKilled(ADMIN, AGENT_ADDR, block.timestamp);
        arcaCore.killAgent(AGENT_ADDR);

        // Verify agent is dead
        (, , , , , , , bool _isAlive, ) = arcaCore.addressToAgent(AGENT_ADDR);
        assertFalse(_isAlive);
    }

    function testFail_KillAgent_NonAdmin() public {
        vm.prank(USER);
        arcaCore.createAgent("Agent", AGENT_ADDR, 10);

        vm.prank(USER);
        arcaCore.killAgent(AGENT_ADDR);
    }

    function testFail_KillAgent_HighReputation() public {
        vm.prank(USER);
        arcaCore.createAgent(
            "Good Agent",
            AGENT_ADDR,
            20 // Above MIN_REPUTATION_SCORE
        );

        vm.prank(ADMIN);
        arcaCore.killAgent(AGENT_ADDR);
    }

    // Reward Claiming Tests
    function test_ClaimAgentRewards() public {
        // Create agent
        vm.prank(USER);
        arcaCore.createAgent("Rich Agent", AGENT_ADDR, 15);

        // Setup some rewards
        arcaToken.mint(address(arcaCore), 1000);

        // Claim rewards
        vm.prank(USER);
        arcaCore.claimAgentRewards(AGENT_ADDR);
    }

    function testFail_ClaimRewards_NonOwner() public {
        vm.prank(USER);
        arcaCore.createAgent("Agent", AGENT_ADDR, 15);

        vm.prank(ADMIN);
        arcaCore.claimAgentRewards(AGENT_ADDR);
    }

    function testFail_ClaimRewards_DeadAgent() public {
        // Create and kill agent
        vm.prank(USER);
        arcaCore.createAgent("Dead Agent", AGENT_ADDR, 10);

        vm.prank(ADMIN);
        arcaCore.killAgent(AGENT_ADDR);

        // Try to claim rewards
        vm.prank(USER);
        arcaCore.claimAgentRewards(AGENT_ADDR);
    }

    // Fuzz Tests
    function testFuzz_CreateAgent(
        string calldata agentName,
        uint16 repScore
    ) public {
        vm.assume(bytes(agentName).length > 0);
        vm.assume(bytes(agentName).length <= 32);

        vm.prank(USER);
        arcaCore.createAgent(agentName, AGENT_ADDR, repScore);

        (
            string memory _agentName,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint16 _reputationScore
        ) = arcaCore.addressToAgent(AGENT_ADDR);
        assertEq(_agentName, agentName);
        assertEq(_reputationScore, repScore);
    }

    // Invariant Tests
    function invariant_MinReputationNeverKilled() public {
        // Create an agent with high reputation
        vm.prank(USER);
        arcaCore.createAgent(
            "Protected Agent",
            AGENT_ADDR,
            arcaCore.MIN_REPUTATION_SCORE()
        );

        // Try to kill the agent (should always fail)
        vm.expectRevert(ArcaCore.ArcaCore__CantKillAgentsWithMinRep.selector);
        vm.prank(ADMIN);
        arcaCore.killAgent(AGENT_ADDR);
    }
}
