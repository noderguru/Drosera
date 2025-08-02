## 1️⃣ Автоинсталл в сети holesky системной службой SystemD
🛀🏻 получаем токены в кране https://cloud.google.com/application/web3/faucet/ethereum/holesky

🌍 RPC берём здесь:

▶️ https://www.ankr.com/rpc/eth

▶️ https://dashboard.alchemy.com/apps

▶️ https://dashboard.blockpi.io/rpc/endpoint 

🎯 [или поднимаем свою](https://github.com/noderguru/Ethereum-Testnet_RPCs/tree/main?tab=readme-ov-file#holesky)
```bash
bash <(curl -s https://raw.githubusercontent.com/noderguru/Drosera/main/drosera_autoinstall_inHolesky-ntw.sh)
```
## 2️⃣ Обнова бинарников на последнюю версию. Если вышло очередное обновление то снова запускаем команду - автоматом подтянет свежую
```bash
bash <(curl -s https://raw.githubusercontent.com/noderguru/Drosera/main/update_drosera_operator_to_latestVersion.sh)
```

## 3️⃣ Получаем роль 🔴Cadet💂 в Дискорде Drosera https://discord.gg/acYp8jpR

```bash
curl -L https://foundry.paradigm.xyz | bash && source /root/.bashrc && foundryup
```
```bash
curl -sSL https://raw.githubusercontent.com/noderguru/Drosera/main/drosera-cadet_roleDS.sh -o \
/root/my-drosera-trap/drosera-cadet_roleDS.sh && \
chmod +x /root/my-drosera-trap/drosera-cadet_roleDS.sh && \
/root/my-drosera-trap/drosera-cadet_roleDS.sh
```
## 4️⃣ Переход из Holesky в Hoodi (внутри скрипта будут все необходимые подсказки и команды)
```bash
curl -O https://raw.githubusercontent.com/noderguru/Drosera/main/migrate_from_holesky_to_hoodi.sh && chmod +x migrate_from_holesky_to_hoodi.sh && source migrate_from_holesky_to_hoodi.sh
```
