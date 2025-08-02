#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

cd /root/my-drosera-trap || { echo -e "${RED}❌ Failed to cd into /root/my-drosera-trap${RESET}"; exit 1; }

echo -e "${CYAN}🌍 RPC We take here:${RESET}"
echo -e "▶️ https://www.ankr.com/rpc/eth"
echo -e "▶️ https://dashboard.alchemy.com/apps"
echo -e "▶️ https://dashboard.blockpi.io/rpc/endpoint"
echo -e "\n🎯 or run your own: https://github.com/noderguru/Ethereum-Testnet_RPCs?tab=readme-ov-file#hoodi${RESET}"
echo -e "${MAGENTA}\n===========================================================${RESET}"
echo -ne "${CYAN}Enter your Hoodi network RPC URL: ${RESET}"
read -rp "" RPC_URL

DRO_RPC="https://relay.hoodi.drosera.io"
CHAIN_ID=560048
DRO_ADDRESS="0x91cB447BaFc6e0EA0F4Fe056F5a9b1F14bb06e5D"
RESP_CONTR="0x183D78491555cb69B68d2354F7373cc2632508C7"
TOML_PATH="/root/my-drosera-trap/drosera.toml"
ENV_FILE="$HOME/.drosera_operator.env"
SERVICE_FILE="/etc/systemd/system/drosera.service"

echo -e "${YELLOW}🔧 Updating drosera.toml at ${TOML_PATH}...${RESET}"
# Update top-level settings
sed -i -E \
    -e "s#^ethereum_rpc = \".*\"#ethereum_rpc = \"$RPC_URL\"#" \
    -e "s#^drosera_rpc = \".*\"#drosera_rpc = \"$DRO_RPC\"#" \
    -e "s#^eth_chain_id = .*#eth_chain_id = $CHAIN_ID#" \
    -e "s#^drosera_address = \".*\"#drosera_address = \"$DRO_ADDRESS\"#" \
    -e "s#^response_contract = \".*\"#response_contract = \"$RESP_CONTR\"#" \
    "$TOML_PATH"

sed -i -E "s#^[[:space:]]*address =#\#address =#" "$TOML_PATH"

echo -e "${YELLOW}🔧 Updating operator env in ${ENV_FILE}...${RESET}"
# Ensure the env file exists
mkdir -p "$(dirname "$ENV_FILE")"
touch "$ENV_FILE"
# Replace or add ETH_RPC_URL
if grep -qE '^ETH_RPC_URL=' "$ENV_FILE"; then
    sed -i -E "s#^ETH_RPC_URL=.*#ETH_RPC_URL=$RPC_URL#" "$ENV_FILE"
else
    echo "ETH_RPC_URL=$RPC_URL" >> "$ENV_FILE"
fi

echo -e "${YELLOW}🔧 Updating systemd service at ${SERVICE_FILE}...${RESET}"

sed -i -E \
    "s#--drosera-address[[:space:]]+[^[:space:]]+#--drosera-address $DRO_ADDRESS#" \
    "$SERVICE_FILE"

echo -e "${GREEN}🔒 Reloading systemd to pick up changes...${RESET}"
systemctl daemon-reload

echo -e "${BLUE}📂 Adding drosera CLI to PATH in ~/.bashrc...${RESET}"

grep -qxF 'export PATH="/root/.drosera/bin:$PATH"' ~/.bashrc || \
    echo 'export PATH="/root/.drosera/bin:$PATH"' >> ~/.bashrc

echo -e "\n${MAGENTA}✅ Configuration complete!${RESET} ${CYAN}Next steps:${RESET}\n"

echo -e "${CYAN}\nRequest test tokens for the Hoodi network in any of the fausets:${RESET}"
echo -e "1) https://stakely.io/faucet/ethereum-hoodi-testnet-eth"
echo -e "2) https://tatum.io/faucets/hoodi"
echo -e "3) https://faucet.quicknode.com/ethereum/hoodi"

echo -e "${MAGENTA}\n===========================================================${RESET}"

echo -e "${CYAN}⚠️  Please reload your shell environment to pick up the new PATH:${RESET}"
echo -e "    ${YELLOW}source ~/.bashrc${RESET}"

echo -e "${GREEN}1) Apply the Trap Config${RESET}"
echo -e "   ${MAGENTA}DROSERA_PRIVATE_KEY=0xYOUR_PRIVATE_KEY drosera apply${RESET}\n"

echo -e "${GREEN}2) Register your Operator${RESET}"
echo -e "   ${MAGENTA}drosera-operator register \\"
echo -e "     --eth-rpc-url \"${RPC_URL}\" \\"
echo -e "     --eth-private-key YOUR_ETH_PRIVATE_KEY \\"
echo -e "     --drosera-address ${DRO_ADDRESS}${RESET}\n"

echo -e "${GREEN}3) Opt-in your Trap Config${RESET}"
echo -e "   First extract the new trap-config-address:"
echo -e "${YELLOW}cat /root/my-drosera-trap/drosera.toml | grep -E '^address\\s*=' | head -n1 | sed -E 's#^address\\s*=\\s*\"([^\"]*)\"#\\1#'${RESET}"
echo -e "   Then run:"
echo -e "     ${MAGENTA}drosera-operator optin \\"
echo -e "       --eth-rpc-url \"${RPC_URL}\" \\"
echo -e "       --eth-private-key YOUR_ETH_PRIVATE_KEY \\"
echo -e "       --trap-config-address your_trap_address_here${RESET}\n"

echo -e "${GREEN}4) Restart the Drosera service${RESET}"
echo -e "   ${MAGENTA}systemctl restart drosera.service${RESET}\n"

echo -e "${GREEN}5) Tail the service logs${RESET}"
echo -e "   ${MAGENTA}journalctl -u drosera.service -f${RESET}\n"
