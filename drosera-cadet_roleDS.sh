#!/bin/bash
set -euo pipefail

export PATH="$HOME/.foundry/bin:$PATH"

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

echo -e "${YELLOW}Enter your private key:${NC}"
read PRIV_KEY
echo
export DROSERA_PRIVATE_KEY="$PRIV_KEY"

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

sed -i 's|^path = .*|path = "out/Trap.sol/Trap.json"|' drosera.toml
sed -i 's|^response_contract = .*|response_contract = "0x4608Afa7f277C8E0BE232232265850d1cDeB600E"|' drosera.toml
sed -i 's|^response_function = .*|response_function = "respondWithDiscordName(string)"|' drosera.toml

echo -e "${BLUE}Start forge build...${NC}"
forge build

echo -e "${BLUE}Start drosera dryrun...${NC}"
drosera dryrun

echo -e "${BLUE}drosera apply...${NC}"
drosera apply

echo -e "${PURPLE}Ожидаем 60 секунд для загрузки...\n${NC}"
sleep 60

while true; do
    echo -e "${YELLOW}Ищем Discord имя $DISCORD в списке подтверждённых пользователей...\n${NC}"

    DISCORD_SEARCH=$(cast call 0x4608Afa7f277C8E0BE232232265850d1cDeB600E \
        "getDiscordNamesBatch(uint256,uint256)(string[])" 0 2000 \
        --rpc-url https://ethereum-holesky-rpc.publicnode.com/ 2>/dev/null | grep -i "$DISCORD" || echo "")

    if [[ -n "$DISCORD_SEARCH" ]]; then
        echo -e "\033[0;32m✅ Discord имя найдено в списке:\033[0m"
        echo -e "\033[0;33m$DISCORD_SEARCH\033[0m"
        break
    else
        echo -e "\033[0;31m❌ Discord имя '$DISCORD' не найдено в списке подтверждённых пользователей.\033[0m"
        echo -e "Ожидание 60 секунд перед повторной проверкой...\n"
        sleep 60
    fi
done

sleep 3
echo -e "${PURPLE}=== Возвращаемся к исходному контракту ===${NC}"

echo -e "${BLUE}Останавливаем системную службу drosera...${NC}"
if systemctl is-active --quiet drosera.service 2>/dev/null; then
    systemctl stop drosera.service
    echo -e "${GREEN}✅ Служба drosera остановлена${NC}"
else
    echo -e "${YELLOW}⚠️ Служба drosera уже остановлена или не существует${NC}"
fi

sleep 2

echo -e "${BLUE}Обновляем файл drosera.toml на старые значения...${NC}"

cp drosera.toml "drosera.toml.backup.$(date +%s)"

sed -i 's|^path = .*|path = "out/HelloWorldTrap.sol/HelloWorldTrap.json"|' drosera.toml
sed -i 's|^response_contract = .*|response_contract = "0xdA890040Af0533D98B9F5f8FE3537720ABf83B0C"|' drosera.toml
sed -i 's|^response_function = .*|response_function = "helloworld(string)"|' drosera.toml

echo -e "${GREEN}✅ Конфигурация drosera.toml обновлена${NC}"
echo -e "${YELLOW}Ждём 15 минут для cooldown...${NC}"
sleep 900
echo -e "${BLUE}Перезаписываем контракт...${NC}"
DROSERA_PRIVATE_KEY="$PRIV_KEY" drosera apply
echo -e "${GREEN}✅ Контракт перезаписан${NC}"

sleep 3

echo -e "${BLUE}Перезапускаем и стартуем службу...${NC}"
systemctl daemon-reload
sleep 2
systemctl start drosera.service

if systemctl is-active --quiet drosera.service; then
    echo -e "${GREEN}✅ Служба drosera успешно запущена${NC}"
else
    echo -e "${RED}❌ Не удалось запустить службу drosera${NC}"
    echo -e "${YELLOW}Статус службы:${NC}"
    systemctl status drosera.service --no-pager
fi

echo -e "${CYAN}"
echo "=========================================="
echo "           "ФИНАЛЬНЫЙ ОТЧЕТ"
echo "=========================================="
echo -e "${NC}"

echo -e "Discord имя: ${YELLOW}$DISCORD${NC}"
if [[ -n "$DISCORD_SEARCH" ]]; then
    echo -e "Discord в списке: ${GREEN}✅ НАЙДЕН${NC}"
else
    echo -e "Discord в списке: ${RED}❌ НЕ НАЙДЕН${NC}"
fi

if systemctl is-active --quiet drosera.service; then
    echo -e "Служба drosera: ${GREEN}✅ ЗАПУЩЕНА${NC}"
else
    echo -e "Служба drosera: ${RED}❌ НЕ ЗАПУЩЕНА${NC}"
fi

echo
echo -e "${GREEN}Скрипт выполнен успешно!${NC}"
echo
echo -e "${YELLOW}Полезные команды:${NC}"
echo "  Статус службы: systemctl status drosera.service"
echo "  Логи службы: journalctl -u drosera.service -f"
echo "  Перезапуск: systemctl restart drosera.service"
