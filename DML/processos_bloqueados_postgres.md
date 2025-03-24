# Identificar Processos Bloqueados no PostgreSQL

## Descrição

Esta query identifica processos no PostgreSQL que estão bloqueados por outros processos. Ela exibe informações sobre o processo bloqueado, o processo bloqueador e a query que cada um está executando.

## Query

```sql
SELECT
    activity.pid,
    activity.usename,
    activity.query,
    blocking.pid AS blocking_id,
    blocking.query AS blocking_query
FROM pg_stat_activity AS activity
JOIN pg_stat_activity AS blocking ON blocking.pid = ANY(pg_blocking_pids(activity.pid));
```

## Explicação Detalhada

* `pg_stat_activity`: Esta visão do sistema fornece informações sobre os processos em execução no PostgreSQL.
* `activity.pid`: O ID do processo (PID) do processo bloqueado.
* `activity.usename`: O nome do usuário que está executando o processo bloqueado.
* `activity.query`: A query que o processo bloqueado está executando.
* `pg_blocking_pids(activity.pid)`: Esta função retorna um array de PIDs dos processos que estão bloqueando o processo com o PID fornecido.
* `blocking.pid AS blocking_id`: O PID do processo bloqueador.
* `blocking.query AS blocking_query`: A query que o processo bloqueador está executando.
* `JOIN pg_stat_activity AS blocking ON blocking.pid = ANY(pg_blocking_pids(activity.pid))`: Esta junção relaciona os processos bloqueados com os processos bloqueadores. A função `ANY` é usada para verificar se o PID do processo bloqueador está presente no array de PIDs retornados por `pg_blocking_pids()`.

## Exemplos de Uso

Esta query pode ser usada para:

* Identificar gargalos de desempenho causados por bloqueios.
* Investigar problemas de concorrência.
* Monitorar processos de longa duração que podem estar bloqueando outros processos.
* Auxiliar na resolução de deadlocks.

## Considerações

* A presença de bloqueios pode indicar problemas de desempenho ou concorrência no banco de dados.
* É importante analisar as queries dos processos bloqueados e bloqueadores para entender a causa do bloqueio.
* Em ambientes de produção, bloqueios prolongados podem afetar a disponibilidade e o desempenho do banco de dados.
* A função `pg_blocking_pids()` retorna um array, por isso o uso do `ANY` na condição de junção.

```
