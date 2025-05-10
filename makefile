-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_KEY := 

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; 

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url $(ALCHEMY_RPC_URL) --private-key $(METAMASK_PRIVATE_KEY) --broadcast

ifeq ($(findstring --network ethereum,$(ARGS)),--network ethereum)
	NETWORK_ARGS := --rpc-url $(ALCHEMY_RPC_URL) --private-key $(METAMASK_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

createSubscription:
	@forge script script/Interactions.s.sol:CreateSubscription $(NETWORK_ARGS)

addConsumer:
	@forge script script/Interactions.s.sol:AddConsumer $(NETWORK_ARGS)

fundSubscription:
	@forge script script/Interactions.s.sol:FundSubscription $(NETWORK_ARGS)

deploy:
	@forge script script/DeployArcaCore.s.sol:DeployArcaCore $(NETWORK_ARGS)

verify:
	@forge verify-contract --chain-id 84532 --watch --constructor-args `cast abi-encode "constructor(uint8,uint8,uint8,uint8,uint8,uint8,uint8,uint8,int8,int8,uint16,address)" "$(DEFAULT_STRENGTH)" "$(DEFAULT_AGILITY)" "$(DEFAULT_INTELLIGENCE)" "$(DEFAULT_WILLPOWER)" "$(DEFAULT_MANIPULATION)" "$(DEFAULT_INTIMIDATION)" "$(DEFAULT_STEALTH)" "$(DEFAULT_PERCEPTION)" "$(DEFAULT_MORALITY)" "$(DEFAULT_REPUTATION)" "$(DEFAULT_WEALTH)" "$(ARKA_TOKEN)"` --etherscan-api-key $(ETHERSCAN_API_KEY) --compiler-version 0.8.27 0xf61f0B43AA5E757a77564FD88D2fbB566FFfbF79 src/ArcaCore.sol:ArcaCore

#@forge verify-contract --chain-id 84532 --watch --etherscan-api-key $(ETHERSCAN_API_KEY) --compiler-version 0.8.27 0xb9b07CA3a964F21335D23E85ef0C380102a13185 src/KuriCoreFactory.sol:KuriCoreFactory


