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

echo -e "${YELLOW}Enter your private key:${NC}"
read -s PRIV_KEY
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

# Проверяем установку Foundry (forge и cast)
if ! command -v forge &> /dev/null || ! command -v cast &> /dev/null; then
    echo -e "${CYAN}Install Foundry (forge + cast)...${NC}"
    curl -L https://foundry.paradigm.xyz | bash
    
    # Безопасно загружаем .bashrc без ошибок PS1
    if [[ -f ~/.bashrc ]]; then
        set +u  # Временно отключаем проверку неопределенных переменных
        source ~/.bashrc 2>/dev/null || true
        set -u  # Включаем обратно
    fi
    
    # Альтернативно загружаем .zshrc
    if [[ -f ~/.zshrc ]]; then
        set +u
        source ~/.zshrc 2>/dev/null || true
        set -u
    fi
    
    # Запускаем foundryup
    foundryup
    
    # Обновляем PATH для текущей сессии
    export PATH="$HOME/.foundry/bin:$PATH"
    
    # Проверяем что установка прошла успешно
    if ! command -v forge &> /dev/null || ! command -v cast &> /dev/null; then
        echo -e "${RED}Error: Не удалось установить Foundry. Попробуйте выполнить вручную:${NC}"
        echo -e "${YELLOW}source ~/.bashrc && foundryup${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Foundry успешно установлен${NC}"
fi

echo -e "${BLUE}Start forge build...${NC}"
forge build

echo -e "${BLUE}Start drosera dryrun...${NC}"
drosera dryrun

echo -e "${BLUE}drosera apply...${NC}"
drosera apply

# Функция для получения адреса кошелька из приватного ключа
get_wallet_address() {
    local private_key=$1
    
    # cast уже проверен выше, но дополнительная проверка не помешает
    if ! command -v cast &> /dev/null; then
        echo -e "${RED}Error: cast не найден. Foundry не установлен корректно.${NC}"
        exit 1
    fi
    
    local wallet_address=$(cast wallet address --private-key "$private_key" 2>/dev/null)
    
    if [[ -z "$wallet_address" ]]; then
        echo -e "${RED}Error: Не удалось получить адрес кошелька из приватного ключа${NC}"
        exit 1
    fi
    
    echo "$wallet_address"
}

# Получаем адрес кошелька
echo -e "${BLUE}Получаем адрес кошелька из приватного ключа...${NC}"
WALLET_ADDRESS=$(get_wallet_address "$PRIV_KEY")
echo -e "${GREEN}Адрес кошелька: $WALLET_ADDRESS${NC}"

# Пауза для загрузки
echo -e "${YELLOW}Ожидаем 5 секунд для загрузки...${NC}"
sleep 5

# Шаг 2: Проверяем что всё удачно завершилось
echo -e "${PURPLE}=== Шаг 2: Проверяем статус ответчика ===${NC}"
source /root/.bashrc

echo -e "${BLUE}Проверяем статус ответчика для адреса: $WALLET_ADDRESS${NC}"
RESPONDER_STATUS=$(cast call 0x4608Afa7f277C8E0BE232232265850d1cDeB600E \
    "isResponder(address)(bool)" \
    "$WALLET_ADDRESS" \
    --rpc-url https://ethereum-holesky-rpc.publicnode.com 2>/dev/null || echo "false")

if [[ "$RESPONDER_STATUS" == "true" ]]; then
    echo -e "${GREEN}✅ Статус ответчика: АКТИВЕН (true)${NC}"
else
    echo -e "${RED}❌ Статус ответчика: НЕ АКТИВЕН ($RESPONDER_STATUS)${NC}"
fi

# Пауза
sleep 3

# Шаг 3: Просматриваем список подтверждённых Discord юзернеймов
echo -e "${PURPLE}=== Шаг 3: Ищем Discord имя в списке ===${NC}"
echo -e "${BLUE}Ищем Discord имя '$DISCORD' в списке подтверждённых пользователей...${NC}"

DISCORD_SEARCH=$(cast call 0x4608Afa7f277C8E0BE232232265850d1cDeB600E \
    "getDiscordNamesBatch(uint256,uint256)(string[])" 0 2000 \
    --rpc-url https://ethereum-holesky-rpc.publicnode.com/ 2>/dev/null | grep -i "$DISCORD" || echo "")

if [[ -n "$DISCORD_SEARCH" ]]; then
    echo -e "${GREEN}✅ Discord имя найдено в списке:${NC}"
    echo -e "${GREEN}$DISCORD_SEARCH${NC}"
else
    echo -e "${RED}❌ Discord имя '$DISCORD' не найдено в списке подтверждённых пользователей${NC}"
fi

# Пауза
sleep 3

# Шаг 4: Возвращаемся к исходному контракту
echo -e "${PURPLE}=== Шаг 4: Возвращаемся к исходному контракту ===${NC}"

# 4.1: Останавливаем системную службу
echo -e "${BLUE}4.1: Останавливаем системную службу drosera...${NC}"
if systemctl is-active --quiet drosera.service 2>/dev/null; then
    systemctl stop drosera.service
    echo -e "${GREEN}✅ Служба drosera остановлена${NC}"
else
    echo -e "${YELLOW}⚠️ Служба drosera уже остановлена или не существует${NC}"
fi

sleep 2

# 4.2: Меняем файл drosera.toml на старые значения
echo -e "${BLUE}4.2: Обновляем файл drosera.toml на старые значения...${NC}"

# Создаем резервную копию
cp drosera.toml "drosera.toml.backup.$(date +%s)"

# Меняем на старые значения
sed -i 's|^path = .*|path = "out/HelloWorldTrap.sol/HelloWorldTrap.json"|' drosera.toml
sed -i 's|^response_contract = .*|response_contract = "0xdA890040Af0533D98B9F5f8FE3537720ABf83B0C"|' drosera.toml
sed -i 's|^response_function = .*|response_function = "helloworld(string)"|' drosera.toml

echo -e "${GREEN}✅ Конфигурация drosera.toml обновлена${NC}"

sleep 2

# 4.3: Перезаписываем контракт
echo -e "${BLUE}4.3: Перезаписываем контракт...${NC}"
DROSERA_PRIVATE_KEY="$PRIV_KEY" drosera apply
echo -e "${GREEN}✅ Контракт перезаписан${NC}"

sleep 3

# 4.4: Перезапускаем и стартуем
echo -e "${BLUE}4.4: Перезапускаем и стартуем службу...${NC}"
systemctl daemon-reload
sleep 2
systemctl start drosera.service

# Проверяем статус службы
if systemctl is-active --quiet drosera.service; then
    echo -e "${GREEN}✅ Служба drosera успешно запущена${NC}"
else
    echo -e "${RED}❌ Не удалось запустить службу drosera${NC}"
    echo -e "${YELLOW}Статус службы:${NC}"
    systemctl status drosera.service --no-pager
fi

# Финальный отчет
echo -e "${CYAN}"
echo "=========================================="
echo "           ФИНАЛЬНЫЙ ОТЧЕТ"
echo "=========================================="
echo -e "${NC}"

echo -e "Discord имя: ${YELLOW}$DISCORD${NC}"
echo -e "Адрес кошелька: ${YELLOW}$WALLET_ADDRESS${NC}"

if [[ "$RESPONDER_STATUS" == "true" ]]; then
    echo -e "Статус ответчика: ${GREEN}✅ АКТИВЕН${NC}"
else
    echo -e "Статус ответчика: ${RED}❌ НЕ АКТИВЕН${NC}"
fi

if [[ -n "$DISCORD_SEARCH" ]]; then
    echo -e "Discord в списке: ${GREEN}✅ НАЙДЕН${NC}"
else
    echo -e "Discord в списке: ${RED}❌ НЕ НАЙДЕН${NC}"
fi

echo -e "Конфигурация: ${GREEN}✅ ВОССТАНОВЛЕНА${NC}"

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
