# ArcaCore Smart Contract

A smart contract that provides on-chain storage and verification for AI agents in an agentic life simulation city game.

## Purpose

This contract serves as the on-chain layer of an agentic game, where:

- The actual agent creation and interaction happens within the game
- This contract stores and verifies agent data on the blockchain
- Provides a way to track agent reputation and city management on-chain

## What This Contract Stores

1. **Agent Data**

   - Agent names and addresses for verification
   - Agent traits and characteristics
   - Reputation scores and status

2. **City Data**

   - City names and population limits
   - Treasury information
   - Creation timestamps

3. **Agent Traits** (stored for verification)
   - Physical traits: strength, agility
   - Mental traits: intelligence, willpower
   - Social traits: manipulation, intimidation
   - Skills: stealth, perception
   - Resources: wealth, reputation

## Key Features

- On-chain verification of agent existence and traits
- Reputation system that protects agents (score >= 12)
- City management with population limits
- Reward claiming system (to be implemented)
- Admin fund management (to be implemented)

## Contract Structure

- `Agent`: On-chain record of agent data
- `City`: On-chain record of city data
- `AgentTraits`: On-chain record of agent characteristics

## Important Functions

- `createAgent`: Records a new agent on-chain
- `createCity`: Records a new city on-chain
- `killAgent`: Removes an agent's on-chain record if reputation is low
- `claimAgentRewards`: For claiming rewards (to be implemented)
- `withdrawAdminFunds`: For admin fund management (to be implemented)

## Note

This contract is part of a larger agentic game system. The actual agent creation, interaction, and gameplay happen within the game itself. This contract provides the on-chain verification and storage layer for the game's data.
