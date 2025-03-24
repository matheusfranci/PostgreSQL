## Descrição

Este script SQL recupera informações detalhadas sobre os bancos de dados no PostgreSQL, incluindo tamanho, espaço em tablespace, estatísticas de desempenho (cache, commits, conflitos, deadlocks) e uso de arquivos temporários. Ele também calcula o tamanho total de todos os bancos de dados e exibe a porcentagem que cada banco de dados ocupa do total.

## Query

```sql
WITH data AS (
    SELECT
        d.oid,
        (SELECT spcname FROM pg_tablespace WHERE oid = d.dattablespace) AS tblspace,
        d.datname AS database_name,
        pg_catalog.pg_get_userbyid(d.datdba) AS owner,
        has_database_privilege(d.datname, 'connect') AS has_access,
        pg_database_size(d.datname) AS size,
        stats_reset,
        blks_hit,
        blks_read,
        xact_commit,
        xact_rollback,
        conflicts,
        deadlocks,
        temp_files,
        temp_bytes
    FROM pg_catalog.pg_database d
    JOIN pg_stat_database s ON s.datid = d.oid
), data2 AS (
    SELECT
        NULL::oid AS oid,
        NULL AS tblspace,
        '*** TOTAL ***' AS database_name,
        NULL AS owner,
        TRUE AS has_access,
        SUM(size) AS size,
        NULL::timestamptz AS stats_reset,
        SUM(blks_hit) AS blks_hit,
        SUM(blks_read) AS blks_read,
        SUM(xact_commit) AS xact_commit,
        SUM(xact_rollback) AS xact_rollback,
        SUM(conflicts) AS conflicts,
        SUM(deadlocks) AS deadlocks,
        SUM(temp_files) AS temp_files,
        SUM(temp_bytes) AS temp_bytes
    FROM data
    UNION ALL
    SELECT NULL::oid, NULL, NULL, NULL, TRUE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
    UNION ALL
    SELECT
        oid,
        tblspace,
        database_name,
        owner,
        has_access,
        size,
        stats_reset,
        blks_hit,
        blks_read,
        xact_commit,
        xact_rollback,
        conflicts,
        deadlocks,
        temp_files,
        temp_bytes
    FROM data
)
SELECT
    database_name || COALESCE(' [' || NULLIF(tblspace, 'pg_default') || ']', '') AS "Database",
    CASE
        WHEN has_access THEN
            pg_size_pretty(size) || ' (' || ROUND(100 * size::NUMERIC / NULLIF(SUM(size) OVER (PARTITION BY (oid IS NULL)), 0), 2)::TEXT || '%)'
        ELSE 'no access'
    END AS "Size",
    (now() - stats_reset)::INTERVAL(0)::TEXT AS "Stats Age",
    CASE
        WHEN blks_hit + blks_read > 0 THEN
            (ROUND(blks_hit * 100::NUMERIC / (blks_hit + blks_read), 2))::TEXT || '%'
        ELSE NULL
    END AS "Cache eff.",
    CASE
        WHEN xact_commit + xact_rollback > 0 THEN
            (ROUND(xact_commit * 100::NUMERIC / (xact_commit + xact_rollback), 2))::TEXT || '%'
        ELSE NULL
    END AS "Committed",
    conflicts AS "Conflicts",
    deadlocks AS "Deadlocks",
    temp_files::TEXT || COALESCE(' (' || pg_size_pretty(temp_bytes) || ')', '') AS "Temp. Files"
FROM data2
ORDER BY oid IS NULL DESC, size DESC NULLS LAST;
```

## Explicação Detalhada

* **`data` CTE:**
    * Recupera informações sobre cada banco de dados da tabela `pg_database` e estatísticas de desempenho da tabela `pg_stat_database`.
    * Inclui o nome do tablespace, o proprietário do banco de dados, o tamanho do banco de dados e várias estatísticas de desempenho.
* **`data2` CTE:**
    * Calcula o tamanho total de todos os bancos de dados e soma as estatísticas de desempenho.
    * Adiciona uma linha com o total e uma linha em branco para melhor formatação.
    * Combina os resultados dos bancos de dados individuais e o total usando `UNION ALL`.
* **Consulta Principal:**
    * Exibe o nome do banco de dados (com o nome do tablespace, se diferente de `pg_default`), o tamanho do banco de dados (e a porcentagem do tamanho total), a idade das estatísticas, a eficiência do cache, a porcentagem de commits bem-sucedidos, o número de conflitos, o número de deadlocks e o uso de arquivos temporários.
    * Formata o tamanho do banco de dados usando `pg_size_pretty` e calcula a porcentagem do tamanho total.
    * Calcula a eficiência do cache e a porcentagem de commits bem-sucedidos.
    * Ordena os resultados pelo total (primeiro) e depois pelo tamanho do banco de dados em ordem decrescente.

## Exemplos de Uso

Esta query pode ser usada para:

* Obter uma visão geral rápida do tamanho e desempenho de todos os bancos de dados.
* Identificar bancos de dados que estão consumindo muito espaço em disco.
* Monitorar as estatísticas de desempenho dos bancos de dados.
* Acompanhar o uso de arquivos temporários.
* Comparar o desempenho de diferentes bancos de dados.

## Considerações

* A coluna "Size" exibe o tamanho do banco de dados e a porcentagem que ele ocupa do tamanho total.
* A coluna "Cache eff." exibe a eficiência do cache de buffer para cada banco de dados.
* A coluna "Committed" exibe a porcentagem de commits bem-sucedidos.
* A coluna "Temp. Files" exibe o número de arquivos temporários e o tamanho total usado por eles.
* A ordenação coloca o total no topo da lista e os bancos de dados maiores no início da lista.
* A query usa funções como `pg_size_pretty` para formatar os tamanhos de forma legível.
* A coluna 'Stats Age' indica a idade das estatísticas coletadas pelo banco de dados.
