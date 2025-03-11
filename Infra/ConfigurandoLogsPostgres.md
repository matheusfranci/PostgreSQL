## Verificação e Alteração dos Logs do PostgreSQL

Este guia detalha os passos para verificar os logs do PostgreSQL, identificar o arquivo de configuração e alterar os parâmetros de log.

### 1. Verificando os Logs

Navegue até o diretório de logs do PostgreSQL e liste os arquivos para identificar o arquivo mais recente:

```bash
cd /var/log/postgresql/
ls -lisah
```

Abra o arquivo de log mais recente utilizando o `vim`:

```bash
vim arquivomaisrecente.log
```

### 2. Identificando o Arquivo de Configuração

Identifique o arquivo de configuração do PostgreSQL utilizando o comando `ps`:

```bash
ps -ef | grep postgres
```

Exemplo de saída:

```
postgres 2984207        1  0 May11 ?        00:08:57 /usr/lib/postgresql/12/bin/postgres -D /db01/postgresql/12/main -c config_file=/etc/postgresql/12/main/postgresql.conf
```

Copie o caminho do arquivo de configuração (`/etc/postgresql/12/main/postgresql.conf`).

### 3. Acessando o Arquivo de Configuração

Abra o arquivo de configuração utilizando o `vim`:

```bash
vim /etc/postgresql/12/main/postgresql.conf
```

### 4. Alterando o Parâmetro `log_statement`

Localize o parâmetro `log_statement` e altere o valor desejado:

```
/log_statement
#log_statement = 'none'
```

Valores permitidos para `log_statement`:

* `off`: Logs desabilitados.
* `ddl`: Logs de instruções DDL (Data Definition Language).
* `mod`: Logs de instruções DDL e DML (Data Manipulation Language).
* `all`: Logs de todas as instruções.

Exemplos de alteração:

```
log_statement = 'ddl'
log_statement = 'mod'
log_statement = 'all'
```

### 5. Alterando Outros Parâmetros de Log

Outros parâmetros de log relevantes:

```
log_directory = 'log'        # Define o diretório de logs
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log' # Define o nome dos arquivos de log
log_rotation_age = 1d        # Define o período de rotação dos logs
log_rotation_size = 1GB      # Define o tamanho máximo dos arquivos de log
```
