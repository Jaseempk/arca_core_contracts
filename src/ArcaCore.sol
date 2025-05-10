//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ArcaCore - A decentralized agent-based city management system
/// @author Anon
/// @notice This contract manages agents and cities in the Arca ecosystem
/// @dev Inherits OpenZeppelin's AccessControl for role-based permissions
/// @notice Main contract for managing agents and cities in the Arca ecosystem
contract ArcaCore is AccessControl {
    error ArcaCore__AgentIsNotAlive();
    error ArcCore__AgentAlreadyLive();
    error ArcaCore__InvalidCityParams();
    error ArcCore__InvalidAgentParams();
    error ArcCore__OwnerAgentAlreadyExist();
    error ArcCore__OwnlyAgentOwnerCanClaim();
    error ArcaCore__CityAlreadyInitialised();
    error ArcaCore__CantKillAgentsWithMinRep();

    /// @notice Minimum reputation score required to protect an agent from being killed
    /// @dev Used in killAgent function to prevent killing of reputable agents
    uint16 public constant MIN_REPUTATION_SCORE = 12;

    City city;
    address arcaToken;
    AgentTraits defaultTraits;

    /// @notice Defines the possible roles an agent can have in the system
    /// @dev NONE is default state, POLICE and THIEF are active roles
    enum PERSONAS {
        NONE,
        POLICE,
        THIEF
    }

    /// @notice Defines the traits and characteristics of an agent
    /// @dev All uint8 traits are on 0-100 scale unless specified otherwise
    struct AgentTraits {
        // Combat & Physical Traits (0-100 scale)
        uint8 strength; // Raw physical power, combat effectiveness
        uint8 agility; // Speed, reflexes, physical coordination
        // Mental Traits (0-100 scale)
        uint8 intelligence; // Problem-solving, tactical thinking
        uint8 willpower; // Mental fortitude, resistance to pressure
        // Social Traits (0-100 scale)
        uint8 manipulation; // Ability to influence, deceive, negotiate
        uint8 intimidation; // Ability to threaten, command respect
        // Skill Traits (0-100 scale)
        uint8 stealth; // Sneaking, theft, covert operations
        uint8 perception; // Awareness, investigation skills
        // Moral Compass (-100 to 100 scale)
        int8 morality; // Lawful (+) vs Criminal (-)
        // Resources & Standing
        int8 reputation; // Social standing (-100 to 100)
        uint16 wealth; // Financial resources (0-65535)
    }

    /// @notice Represents an agent in the Arca ecosystem
    /// @dev Stores all relevant information about an agent including their traits and status
    struct Agent {
        string agentName;
        address owner;
        address agentAddy;
        PERSONAS persona;
        uint256 balance;
        AgentTraits agentTraits;
        uint128 agentDOB;
        bool isAlive;
        uint16 reputationScore;
    }

    /// @notice Represents a city in the Arca ecosystem
    /// @dev Stores city-related information and statistics
    struct City {
        string name;
        uint32 currentPopulation;
        uint32 maxPopulation;
        uint128 treasuryBalance;
        uint128 createdAt;
        bool isInitialized;
    }

    /// @notice Maps agent addresses to their data
    /// @dev Primary storage for agent information
    mapping(address => Agent) public addressToAgent;

    mapping(address => address) public ownerToAgent;

    /// @notice Emitted when a new city is created
    /// @param creator Address of the admin who created the city
    /// @param name Name of the city
    /// @param maxPopulation Maximum allowed population for the city
    /// @param createdAt Timestamp of city creation
    event CityCreated(
        address creator,
        string name,
        uint32 maxPopulation,
        uint128 createdAt
    );

    /// @notice Emitted when a new agent is created
    /// @param owner Address of the agent owner
    /// @param agentName Name of the agent
    /// @param agentAddy Address associated with the agent
    /// @param persona Initial role of the agent
    /// @param balance Initial balance of the agent
    /// @param defaultTraits Default trait values assigned to the agent
    /// @param agentDob Timestamp of agent creation
    /// @param reputationScore Initial reputation score
    event AgentCreated(
        address owner,
        string agentName,
        address agentAddy,
        PERSONAS persona,
        uint256 balance,
        AgentTraits defaultTraits,
        uint128 agentDob,
        uint16 reputationScore
    );

    /// @notice Emitted when an agent is killed
    /// @param caller Address of the admin who killed the agent
    /// @param agentAddy Address of the killed agent
    /// @param timestamp Time when the agent was killed
    event AgentKilled(address caller, address agentAddy, uint256 timestamp);

    /// @notice Initializes the contract with default trait values for agents
    /// @dev Sets up initial admin role and default trait values
    /// @param _defaultTraitSrength Default strength value for new agents
    /// @param _defaultTraitAgility Default agility value for new agents
    /// @param _deafaultTraitIntelligence Default intelligence value for new agents
    /// @param _defaultTraitWillpower Default willpower value for new agents
    /// @param _defaultTraitManipulation Default manipulation value for new agents
    /// @param _deafaulTraitIntimidation Default intimidation value for new agents
    /// @param _defaultTraitStealth Default stealth value for new agents
    /// @param _defaultTraitPerception Default perception value for new agents
    /// @param _deafultTraitMorality Default morality value for new agents
    /// @param _defaultTraitReputation Default reputation value for new agents
    /// @param _defaultTraitWealth Default wealth value for new agents
    constructor(
        uint8 _defaultTraitSrength,
        uint8 _defaultTraitAgility,
        uint8 _deafaultTraitIntelligence,
        uint8 _defaultTraitWillpower,
        uint8 _defaultTraitManipulation,
        uint8 _deafaulTraitIntimidation,
        uint8 _defaultTraitStealth,
        uint8 _defaultTraitPerception,
        int8 _deafultTraitMorality,
        int8 _defaultTraitReputation,
        uint16 _defaultTraitWealth,
        address _arkaToken
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        arcaToken = _arkaToken;
        defaultTraits = AgentTraits(
            _defaultTraitSrength,
            _defaultTraitAgility,
            _deafaultTraitIntelligence,
            _defaultTraitWillpower,
            _defaultTraitManipulation,
            _deafaulTraitIntimidation,
            _defaultTraitStealth,
            _defaultTraitPerception,
            _deafultTraitMorality,
            _defaultTraitReputation,
            _defaultTraitWealth
        );
    }

    /// @notice Creates a new city in the ecosystem
    /// @dev Only callable by admin role
    /// @param _name Name of the city
    /// @param _treasuryBalance Initial treasury balance for the city
    /// @param _maxPopulation Maximum allowed population for the city
    /// @custom:requirements City name must not be empty and max population must be > 0
    function createCity(
        string memory _name,
        uint128 _treasuryBalance,
        uint32 _maxPopulation
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (bytes(_name).length == 0 || _maxPopulation == 0)
            revert ArcaCore__InvalidCityParams();
        if (city.isInitialized) revert ArcaCore__CityAlreadyInitialised();

        emit CityCreated(
            msg.sender,
            _name,
            _maxPopulation,
            uint128(block.timestamp)
        );
        city = City(
            _name,
            0,
            _maxPopulation,
            _treasuryBalance,
            uint128(block.timestamp),
            true
        );
    }

    /// @notice Creates a new agent in the ecosystem
    /// @dev Assigns default traits and initializes agent state
    /// @param _agentnName Name of the agent
    /// @param _agentAddy Address associated with the agent
    /// @param _reputationScore Initial reputation score for the agent
    /// @custom:requirements Agent name must not be empty and owner address must be valid
    function createAgent(
        string memory _agentnName,
        address _agentAddy,
        uint16 _reputationScore
    ) external {
        if (bytes(_agentnName).length == 0)
            revert ArcCore__InvalidAgentParams();
        if (addressToAgent[_agentAddy].isAlive)
            revert ArcCore__AgentAlreadyLive();
        if (ownerToAgent[msg.sender] != address(0))
            revert ArcCore__OwnerAgentAlreadyExist();

        uint256 agentBalance = IERC20(arcaToken).balanceOf(_agentAddy);

        emit AgentCreated(
            msg.sender,
            _agentnName,
            _agentAddy,
            PERSONAS.NONE, // or parse _persona to appropriate enum value
            agentBalance,
            defaultTraits,
            uint128(block.timestamp),
            _reputationScore
        );

        Agent memory newAgent = Agent({
            agentName: _agentnName,
            owner: msg.sender,
            agentAddy: _agentAddy,
            persona: PERSONAS.NONE, // or parse _persona to appropriate enum value
            balance: 0,
            agentTraits: defaultTraits,
            agentDOB: uint128(block.timestamp),
            isAlive: true,
            reputationScore: _reputationScore
        });
        ownerToAgent[msg.sender] = _agentAddy;

        addressToAgent[_agentAddy] = newAgent;
    }

    /// @notice Kills an agent in the ecosystem
    /// @dev Only callable by admin role, cannot kill agents with high reputation
    /// @param _agentAddy Address of the agent to kill
    /// @custom:requirements Agent must be alive and have reputation below MIN_REPUTATION_SCORE
    function killAgent(
        address _agentAddy
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Agent storage agent = addressToAgent[_agentAddy];

        if (!agent.isAlive) revert ArcaCore__AgentIsNotAlive();
        if (agent.reputationScore >= MIN_REPUTATION_SCORE)
            revert ArcaCore__CantKillAgentsWithMinRep();

        emit AgentKilled(msg.sender, _agentAddy, block.timestamp);

        delete ownerToAgent[agent.owner];

        delete addressToAgent[_agentAddy];
    }

    /// @notice Allows agent owners to claim their rewards
    /// @dev Currently view function, needs implementation
    /// @param _agentAddy Address of the agent whose rewards are being claimed
    /// @custom:requirements Agent must be alive and caller must be the owner
    function claimAgentRewards(address _agentAddy) external view {
        Agent storage agent = addressToAgent[_agentAddy];
        if (!agent.isAlive) revert ArcaCore__AgentIsNotAlive();
        if (agent.owner != msg.sender)
            revert ArcCore__OwnlyAgentOwnerCanClaim();
    }

    /// @notice Allows admin to withdraw funds from the contract
    /// @dev Only callable by admin role, needs implementation
    function withdrawAdminFunds() external onlyRole(DEFAULT_ADMIN_ROLE) {}
}
