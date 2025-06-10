#!/bin/bash
set -euo pipefail
# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
PROJECT_DIR="$HOME/my-drosera-trap"
cd "$PROJECT_DIR"
echo -e "${YELLOW}Enter Discord-username:${NC}"
read DISCORD
export DISCORD

cat > src/Trap.sol <<EOF
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";
interface IMockResponse {
    function isActive() external view returns (bool);
}
contract Trap is ITrap {
    address public constant RESPONSE_CONTRACT = 0x4608Afa7f277C8E0BE232232265850d1cDeB600E;
    string constant discordName = "${DISCORD}"; // add your discord name here
    function collect() external view returns (bytes memory) {
        bool active = IMockResponse(RESPONSE_CONTRACT).isActive();
        return abi.encode(active, discordName);
    }
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory) {
        // take the latest block data from collect
        (bool active, string memory name) = abi.decode(data[0], (bool, string));
        // will not run if the contract is not active or the discord name is not set
        if (!active || bytes(name).length == 0) {
            return (false, bytes(""));
        }
        return (true, abi.encode(name));
    }
}
EOF

sed -i 's|^path = .|path = "out/Trap.sol/Trap.json"|' drosera.toml
sed -i 's|^response_contract = .|response_contract = "0x4608Afa7f277C8E0BE232232265850d1cDeB600E"|' drosera.toml
sed -i 's|^response_function = .*|response_function = "respondWithDiscordName(string)"|' drosera.toml

if ! command -v forge &> /dev/null; then
    echo -e "${CYAN}Install Foundry (forge)...${NC}"
    curl -L https://foundry.paradigm.xyz | bash
    source ~/.bashrc || source ~/.zshrc || true
    foundryup
fi

echo -e "${BLUE}Start forge build...${NC}"
forge build
echo -e "${BLUE}Start drosera dryrun...${NC}"
drosera dryrun
echo -e "${YELLOW}Enter your private key:${NC}"
read PRIV_KEY
export DROSERA_PRIVATE_KEY="$PRIV_KEY"
echo -e "${BLUE}drosera apply...${NC}"
drosera apply
