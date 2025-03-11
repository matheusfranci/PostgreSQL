## Alterando pg_hba.conf Diretamente no psql

Este guia descreve como modificar o arquivo `pg_hba.conf` diretamente dentro do psql, permitindo alterações dinâmicas nas regras de acesso do PostgreSQL.

### 1. Descobrindo a Localização do pg_hba.conf

Primeiro, identifique a localização do arquivo `pg_hba.conf` usando a seguinte consulta:

```sql
select setting from pg_settings where name like '%hba%';
```

A saída exibirá o caminho do arquivo:

```
setting
------------------------------------------------
/var/lib/postgresql/data/guacamole/pg_hba.conf
(1 row)
```

### 2. Criando uma Tabela Temporária

Crie uma tabela temporária para armazenar as linhas do arquivo `pg_hba.conf`:

```sql
create table hba ( lines text );
```

### 3. Importando o Conteúdo do pg_hba.conf

Importe o conteúdo do arquivo `pg_hba.conf` para a tabela `hba`:

```sql
copy hba from '/var/lib/postgresql/data/guacamole/pg_hba.conf';
```

### 4. Verificando o Conteúdo Importado

Realize uma consulta de teste para verificar o conteúdo importado, excluindo comentários e linhas em branco:

```sql
select * from hba where lines !~ '^#' and lines !~ '^$';
```

### 5. Inserindo Novas Regras no pg_hba.conf

Insira as novas regras de acesso na tabela `hba`:

```sql
insert into hba (lines) values ('host    all             zbx_monitor             127.0.0.1/32              trust');
insert into hba (lines) values ('host    all             zbx_monitor             0.0.0.0/0                 md5');
insert into hba (lines) values ('host    all             zbx_monitor             ::0/0                   md5');
```

### 6. Exportando o Conteúdo da Tabela para o pg_hba.conf

Exporte o conteúdo da tabela `hba` de volta para o arquivo `pg_hba.conf`:

```sql
copy hba to '/var/lib/postgresql/data/guacamole/pg_hba.conf';
```

### 7. Verificando as Alterações

Verifique as alterações no arquivo `pg_hba.conf`:

```sql
select pg_read_file('pg_hba.conf');
```

### 8. Recarregando a Configuração do PostgreSQL

Recarregue a configuração do PostgreSQL para aplicar as alterações:

```sql
select pg_reload_conf();
```
