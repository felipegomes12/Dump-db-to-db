# Dump db to db

nesse projeto está disponível um script que permite sincronizar  um banco de dados mysql ou mariadb com outro, isso é util em casos como migração de banco de dados ou uma relação entre um banco de dados de homologação com um de produção.

## Instalação
### SQL Client
caso não tenha instalado nem o mysql-client nem o mariadb-client siga os paços a baixo para instalar.
#### Mysql
```bash
sudo apt update
sudo apt install mysql-client
```
#### Mariadb
```bash
sudo apt update
sudo apt install mariadb-client
```
### db_sync.sh
```bash
sudo curl -L https://raw.githubusercontent.com/felipegomes12/Dump-db-to-db/main/db_sync.sh -o /usr/local/bin/db_sync.sh
sudo chmod +x /usr/local/bin/db_sync.sh 
```
## Uso
### db_sync.sh
A primeira vez que o comando for executado irá pedir as credenciais para acessar tanto o banco de dados de produção quanto de homologação, o script irá criar um arquivo de configuração chamado db_config.txt na mesma pasta em que o script está salvo, caso queira resetar as configurações só é necessario apagar esse arquivo.
```shell
sudo db_sync.sh
```
### add-ignore
Esse argumento permite ignorar tabelas expecificas na no dump.
```shell
sudo db_sync.sh --add-ignore
```
### remove-ignore
Esse argumento permite retirar uma tabela da lista de ignorados no dump.
```shell
sudo db_sync.sh --remove-ignore
```
### list-ignore
Esse argumento permite listar os ignorados no dump.
```shell
sudo db_sync.sh --list-ignore
```
## requerimentos
- Sitema linux.
- Acesso ao root ou a senha do root.
- Link do repositorio publico ou link com token do repositorio caso seja privado.
- mysql-client ou mariadb-client.
- 2 bancos de dados distintos.
## Permições
Qualquer um é livre para baixar os arquivos e alterar para suprir suas necessidades.
