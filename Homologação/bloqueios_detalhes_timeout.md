# Identificar Bloqueios com Detalhes e Timeout no PostgreSQL

## Descrição

Este script SQL identifica processos bloqueados e bloqueadores no PostgreSQL, exibindo detalhes como ID do processo (PID), processos bloqueadores, tempo de transação, tempo de mudança de estado, ID de transação (XID), ID mínimo de transação (XMIN), estado da conexão, nome do banco de dados, nome do usuário, evento de espera, número de processos bloqueados e a consulta em execução. Ele utiliza uma CTE recursiva para construir uma árvore de dependência de bloqueios e define um timeout de 100ms para a execução da consulta.

## Query

```sql
BEGIN;

SET LOCAL statement_timeout TO '100ms';

WITH RECURSIVE activity AS (
    SELECT
        pg_blocking_pids(pid) AS blocked_by,
        *,
        AGE(CLOCK_TIMESTAMP(), xact_start)::INTERVAL(0) AS tx_age,
        AGE(CLOCK_TIMESTAMP(), state_change)::INTERVAL(0) AS state_age
    FROM pg_stat_activity
    WHERE state IS DISTINCT FROM 'idle'
),
blockers AS (
    SELECT
        ARRAY_AGG(DISTINCT c ORDER BY c) AS pids
    FROM (
        SELECT UNNEST(blocked_by)
        FROM activity
    ) AS dt(c)
),
tree AS (
    SELECT
        activity.*,
        1 AS level,
        activity.pid AS top_blocker_pid,
        ARRAY[activity.pid] AS path,
        ARRAY[activity.pid]::INT[] AS all_blockers_above
    FROM activity, blockers
    WHERE
        ARRAY[pid] <@ blockers.pids
        AND blocked_by = '{}'::INT[]
    UNION ALL
    SELECT
        activity.*,
        tree.level + 1 AS level,
        tree.top_blocker_pid,
        path || ARRAY[activity.pid] AS path,
        tree.all_blockers_above || ARRAY_AGG(activity.pid) OVER () AS all_blockers_above
    FROM activity, tree
    WHERE
        NOT ARRAY[activity.pid] <@ tree.all_blockers_above
        AND activity.blocked_by <> '{}'::INT[]
        AND activity.blocked_by <@ tree.all_blockers_above
)
SELECT
    pid,
    blocked_by,
    tx_age,
    state_age,
    backend_xid AS xid,
    backend_xmin AS xmin,
    REPLACE(state, 'idle in transaction', 'idletx') AS state,
    datname,
    usename,
    wait_event_type || ':' || wait_event AS wait,
    (SELECT COUNT(DISTINCT t1.pid) FROM tree t1 WHERE ARRAY[tree.pid] <@ t1.path AND t1.pid <> tree.pid) AS blkd,
    FORMAT(
        '%s %s%s',
        LPAD('[' || pid::TEXT || ']', 7, ' '),
        REPEAT('.', level - 1) || CASE WHEN level > 1 THEN ' ' END,
        LEFT(query, 1000)
    ) AS query
FROM tree
ORDER BY top_blocker_pid, level, pid;

COMMIT;
```

## Explicação Detalhada

1.  **`BEGIN;` e `COMMIT;`**: Delimitam uma transação, garantindo que as configurações locais (como `statement_timeout`) sejam aplicadas apenas durante a execução da consulta.

2.  **`SET LOCAL statement_timeout TO '100ms';`**: Define um timeout de 100ms para a execução da consulta. Se a consulta não for concluída dentro desse tempo, ela será cancelada.

3.  **`activity` CTE:**
    * Recupera informações sobre processos ativos da tabela `pg_stat_activity`.
    * Utiliza a função `pg_blocking_pids()` para identificar os processos bloqueadores.
    * Calcula o tempo de transação (`tx_age`) e o tempo de mudança de estado (`state_age`).
    * Filtra processos inativos (`state IS DISTINCT FROM 'idle'`).

4.  **`blockers` CTE:**
    * Agrupa os IDs dos processos bloqueadores em um array.

5.  **`tree` CTE:**
    * Constrói uma árvore de dependência de bloqueios usando recursão.
    * Identifica o processo bloqueador principal (`top_blocker_pid`).
    * Cria um array (`path`) representando o caminho de bloqueio.
    * Cria um array (`all_blockers_above`) contendo todos os processos bloqueadores acima na hierarquia.

6.  **Consulta Principal:**
    * Seleciona as informações relevantes sobre os processos bloqueados e bloqueadores.
    * Formata a consulta para facilitar a leitura, incluindo o PID, o caminho de bloqueio e a consulta em execução.
    * Ordena os resultados pelo processo bloqueador principal, nível de bloqueio e PID.

## Exemplos de Uso

Este script pode ser usado para:

* Identificar processos bloqueados e bloqueadores em um banco de dados PostgreSQL.
* Analisar a hierarquia de bloqueios e identificar a causa raiz dos problemas de desempenho.
* Monitorar o tempo de espera e o estado das conexões bloqueadas.
* Liberar recursos do banco de dados finalizando processos bloqueados ou bloqueadores.
* Auxiliar na otimização de consultas e transações para evitar bloqueios.

## Considerações

* O timeout de 100ms pode ser ajustado conforme a necessidade.
* A CTE recursiva `tree` pode levar tempo para ser executada em bancos de dados com muitos bloqueios.
* A formatação da consulta na consulta principal facilita a leitura dos resultados.
* A coluna `blkd` indica o número de processos bloqueados diretamente pelo processo atual.
* A coluna `path` mostra o caminho de bloqueio, permitindo identificar a hierarquia de bloqueios.
* A coluna `all_blockers_above` contém todos os processos bloqueadores acima na hierarquia, facilitando a identificação de deadlocks.
* A opção `replace(state, 'idle in transaction', 'idletx')` resume o estado da transação.
* A coluna `wait` mostra o evento de espera, que pode ajudar a identificar o recurso que está causando o bloqueio.
* Este script é uma ferramenta poderosa para diagnosticar e resolver problemas de bloqueio no PostgreSQL.
* O script utiliza a função `pg_blocking_pids` que é nativa do postgres para identificar os processos bloqueadores.
