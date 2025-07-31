## 1) Автоинсталл в сети holesky системной службой SystemD
--- получаем токены в кране https://cloud.google.com/application/web3/faucet/ethereum/holesky

--- RPC берём здесь https://www.ankr.com/rpc/eth или https://dashboard.alchemy.com/apps или https://dashboard.blockpi.io/rpc/endpoint
```bash
bash <(curl -s https://raw.githubusercontent.com/noderguru/Drosera/main/drosera_autoinstall_inHolesky-ntw.sh)
```
## 2) Обнова на самую последнюю версию. Если вышло очередное обновление то снова запускаем команду - автоматом подтянет свежую
```bash
bash <(curl -s https://raw.githubusercontent.com/noderguru/Drosera/main/update_drosera_operator_to_latestVersion.sh)
```

## 3) Получаем роль 🔴Cadet💂 в Дискорде Drosera https://discord.gg/acYp8jpR

```bash
curl -L https://foundry.paradigm.xyz | bash && source /root/.bashrc && foundryup
```
```bash
curl -sSL https://raw.githubusercontent.com/noderguru/Drosera/main/drosera-cadet_roleDS.sh -o \
/root/my-drosera-trap/drosera-cadet_roleDS.sh && \
chmod +x /root/my-drosera-trap/drosera-cadet_roleDS.sh && \
/root/my-drosera-trap/drosera-cadet_roleDS.sh
```
