## Получаем роль Cadet в ДС Drosera

#### 1. Скачиваем и запускаем скрипт
```bash
curl -sSL https://raw.githubusercontent.com/noderguru/Drosera_cadet_roleDS/main/drosera-cadet_roleDS.sh -o /root/my-drosera-trap/drosera-cadet_roleDS.sh && chmod +x /root/my-drosera-trap/drosera-cadet_roleDS.sh && /root/my-drosera-trap/drosera-cadet_roleDS.sh
```
#### 2. Проверям что всё удачно завершилось - в ответе должно быть "true"
```bash
source /root/.bashrc
cast call 0x4608Afa7f277C8E0BE232232265850d1cDeB600E "isResponder(address)(bool)" МЕНЯЕМ НА СВОЙ АДРЕС КОШ --rpc-url https://ethereum-holesky-rpc.publicnode.com
```
#### 3. Просмотреть список подтверждённых дискорд юзернеймов, подсветится твой
```bash
cast call 0x4608Afa7f277C8E0BE232232265850d1cDeB600E \
  "getDiscordNamesBatch(uint256,uint256)(string[])" 0 2000 \
  --rpc-url https://ethereum-holesky-rpc.publicnode.com/ | grep -i "ДИСКОРД НИК"
```
#### 4. Возвращаемся к исходному контракту 
#### 4.1 останавливаем системную службу
```bash
systemctl stop drosera.service
```
#### 4.2 в файле drosera.toml меням на старые значения
```bash
path = "out/HelloWorldTrap.sol/HelloWorldTrap.json"
response_contract = "0xdA890040Af0533D98B9F5f8FE3537720ABf83B0C"
response_function = "helloworld(string)"
```
#### 4.3 Перезаписываем контракт
```bash
DROSERA_PRIVATE_KEY=ПРИВАТНИК drosera apply
```
#### 4.4 Перезапускаем и стартуем 
```bash
systemctl daemon-reload && systemctl start drosera.service
```





