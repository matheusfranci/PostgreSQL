## Backup e Exportação de Dados no PostgreSQL

Este guia detalha os passos para criar um diretório de backup, restaurar um banco de dados a partir de um dump SQL e exportar dados para arquivos HTML e CSV.

### 1. Criando o Diretório de Backup

Crie um diretório para armazenar os backups:

```bash
mkdir /backup
```

### 2. Definindo Permissões do Diretório de Backup

Defina as permissões corretas para o diretório de backup, concedendo acesso apenas ao usuário e grupo `postgres`:

```bash
chown postgres:postgres /backup/ -R
chmod -R 700 /backup
```

### 3. Restaurando um Banco de Dados a partir de um Dump SQL

Restaure um banco de dados a partir de um arquivo de dump SQL, direcionando a saída e erros para um arquivo de log:

```bash
psql -d brasil < /backup/brasil.sql >> /backup/brasil.log 2>&1
```

* `psql -d brasil`: Conecta ao banco de dados "brasil".
* `< /backup/brasil.sql`: Redireciona a entrada do arquivo de dump SQL.
* `>> /backup/brasil.log 2>&1`: Redireciona a saída e erros para o arquivo de log.

### 4. Exportando Dados para um Arquivo HTML

Exporte os dados de uma tabela para um arquivo HTML:

```bash
psql -d brasil -A -H -c "select * from weather_conditions;" > tempo.html
```

* `psql -d brasil`: Conecta ao banco de dados "brasil".
* `-A`: Desabilita a saída alinhada.
* `-H`: Gera saída em formato HTML.
* `-c "select * from weather_conditions;"`: Executa a consulta SQL e inclui na exportação.
* `> tempo.html`: Redireciona a saída para o arquivo HTML.

### 5. Exportando Dados para um Arquivo CSV

Exporte os dados de uma tabela para um arquivo CSV:

```bash
psql -d brasil -A -F ";" -c "select * from weather_conditions;" > tempo.csv
```

* `psql -d brasil`: Conecta ao banco de dados "brasil".
* `-A`: Desabilita a saída alinhada.
* `-F ";"`: Define o delimitador de campo como ponto e vírgula.
* `-c "select * from weather_conditions;"`: Executa a consulta SQL e inclui na exportação.
* `> tempo.csv`: Redireciona a saída para o arquivo CSV.
