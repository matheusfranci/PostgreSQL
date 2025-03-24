# Informações sobre Bloqueios de Tabelas no PostgreSQL

## Descrição

Esta query recupera informações detalhadas sobre os bloqueios (locks) em tabelas do PostgreSQL. Ela exibe o nome da tabela, a query que está segurando o bloqueio e detalhes sobre o bloqueio em si.

## Query

```sql
SELECT
    relname AS relation_name,
    query,
    pg_locks.*
FROM pg_locks
JOIN pg_class ON pg_locks.relation = pg_class.oid
JOIN pg_stat_activity ON pg_locks.pid = pg_stat_activity.pid;
```

## Explicação Detalhada

* `pg_locks`: Esta visão do sistema contém informações sobre os bloqueios atualmente em vigor no servidor PostgreSQL.
* `pg_class`: Esta tabela do sistema contém informações sobre relações (tabelas, índices, etc.).
* `pg_stat_activity`: Esta visão do sistema contém informações sobre as atividades em execução no servidor PostgreSQL.
* `relname AS relation_name`: Nome da tabela que está sendo bloqueada.
* `query`: A query que está segurando o bloqueio.
* `pg_locks.*`: Todas as colunas da tabela `pg_locks`, que fornecem detalhes sobre o bloqueio (tipo de bloqueio, modo, etc.).
* `JOIN pg_class ON pg_locks.relation = pg_class.oid`: Junta `pg_locks` com `pg_class` para obter o nome da tabela.
* `JOIN pg_stat_activity ON pg_locks.pid = pg_stat_activity.pid`: Junta `pg_locks` com `pg_stat_activity` para obter a query associada ao bloqueio.

## Exemplos de Uso

Esta query pode ser usada para:

* Identificar bloqueios que estão impedindo outras queries de serem executadas.
* Diagnosticar problemas de desempenho causados por bloqueios.
* Monitorar bloqueios em tabelas críticas.
* Auxiliar na resolução de deadlocks.

## Considerações

* A presença de bloqueios pode indicar problemas de concorrência no banco de dados.
* É importante analisar a query que está segurando o bloqueio para entender a causa do bloqueio.
* Bloqueios prolongados podem afetar a disponibilidade e o desempenho do banco de dados.
* A coluna `pg_locks.mode` indica o tipo de bloqueio (por exemplo, `ACCESS SHARE`, `ACCESS EXCLUSIVE`).
* A coluna `pg_locks.locktype` indica o tipo de objeto que está sendo bloqueado (por exemplo, `relation`, `transactionid`).
* A coluna `pg_locks.granted` indica se o bloqueio foi concedido.
* A coluna 'pg_stat_activity.query' will show the last query run by a process, not necessarily the exact query that created the lock.
