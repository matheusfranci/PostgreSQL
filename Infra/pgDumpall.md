## Backup e Restauração de Banco de Dados PostgreSQL

Este guia detalha os procedimentos para realizar backup completo (roles e dados) e restauração de um banco de dados PostgreSQL, utilizando `pg_dumpall` e `psql`.

### Observações Importantes

* **Opções de Restauração:**
    * Para remover objetos de banco de dados antes de recriá-los, utilize a opção `-c` no `psql`.
    * Para construir um banco de dados antes de restaurá-lo, utilize a opção `-C` no `psql`.
* **Backup de Roles (Usuários):**
    * O comando `pg_dump` não exporta roles (usuários). Para incluir roles no backup, é necessário utilizar `pg_dumpall`.

### 1. Backup Completo (Roles e Dados)

Para realizar um backup completo de todos os bancos de dados e roles, utilize `pg_dumpall`:

```bash
pg_dumpall --roles-only > c:\pgdump\allroles.sql
pg_dumpall -p 5432 -U postgres -h hostname > cluster.sql
```

* `pg_dumpall`: Comando para realizar backup completo.
* `--roles-only`: Comando utilizado somente para roles.
* `-p 5432`: Porta do servidor PostgreSQL.
* `-U postgres`: Nome do usuário para conectar ao banco de dados.
* `-h hostname`: Nome do host do servidor PostgreSQL.
* `> cluster.sql`: Redireciona a saída do comando para um arquivo chamado `cluster.sql`.

### 2. Restauração do Banco de Dados

Para restaurar o banco de dados a partir do arquivo de backup (`cluster.sql`), utilize `psql`:

```bash
psql -p 5432 -U postgres -h hostname -f /caminho/do/arquivo.sql
```

* `-p 5432`: Porta do servidor PostgreSQL.
* `-U postgres`: Nome do usuário para conectar ao banco de dados.
* `-h hostname`: Nome do host do servidor PostgreSQL.
* `-f /caminho/do/arquivo.sql`: Especifica o caminho para o arquivo de backup.

Para Restauração com recriação dos objetos, utilize a opção -c:

```bash
psql -p 5432 -U postgres -h hostname -c -f /caminho/do/arquivo.sql
```
