# Status do VACUUM em Tabelas no PostgreSQL

## Descrição

Este script SQL recupera informações detalhadas sobre o status do `VACUUM` em tabelas do PostgreSQL. Ele inclui informações sobre o percentual de tuplas mortas, configurações de `VACUUM` por tabela, data da última execução do `VACUUM`, progresso do `VACUUM` em andamento, e outras métricas relevantes.

## Query

```sql
WITH table_opts AS (
    SELECT
        pg_class.oid,
        relname,
        nspname,
        ARRAY_TO_STRING(reloptions, '') AS relopts
    FROM pg_class
    JOIN pg_namespace ns ON relnamespace = ns.oid
), vacuum_settings AS (
    SELECT
        oid,
        relname,
        nspname,
        CASE
            WHEN relopts LIKE '%autovacuum_vacuum_threshold%' THEN REGEXP_REPLACE(relopts, '.*autovacuum_vacuum_threshold=([0-9.]+).*', E'\\1')::INT8
            ELSE CURRENT_SETTING('autovacuum_vacuum_threshold')::INT8
        END AS autovacuum_vacuum_threshold,
        CASE
            WHEN relopts LIKE '%autovacuum_vacuum_scale_factor%' THEN REGEXP_REPLACE(relopts, '.*autovacuum_vacuum_scale_factor=([0-9.]+).*', E'\\1')::NUMERIC
            ELSE CURRENT_SETTING('autovacuum_vacuum_scale_factor')::NUMERIC
        END AS autovacuum_vacuum_scale_factor,
        CASE WHEN relopts ~ 'autovacuum_enabled=(false|off)' THEN FALSE ELSE TRUE END AS autovacuum_enabled
    FROM table_opts
), p AS (
    SELECT *
    FROM pg_stat_progress_vacuum
)
SELECT
    COALESCE(
        COALESCE(NULLIF(vacuum_settings.nspname, 'public') || '.', '') || vacuum_settings.relname, -- current DB
        FORMAT('[something in "%I"]', p.datname)
    ) AS table,
    ROUND((100 * psat.n_dead_tup::NUMERIC / NULLIF(pg_class.reltuples, 0))::NUMERIC, 2) AS dead_tup_pct,
    pg_class.reltuples::NUMERIC,
    psat.n_dead_tup,
    'vt: ' || vacuum_settings.autovacuum_vacuum_threshold || ', vsf: ' || vacuum_settings.autovacuum_vacuum_scale_factor || CASE WHEN NOT autovacuum_enabled THEN ', DISABLED' ELSE ', enabled' END AS "effective_settings",
    CASE
        WHEN last_autovacuum > COALESCE(last_vacuum, '0001-01-01') THEN LEFT(last_autovacuum::TEXT, 19) || ' (auto)'
        WHEN last_vacuum IS NOT NULL THEN LEFT(last_vacuum::TEXT, 19) || ' (manual)'
        ELSE NULL
    END AS "last_vacuumed",
    COALESCE(p.phase, '~~~ in queue ~~~') AS status,
    p.pid AS pid,
    CASE
        WHEN a.query ~ '^autovacuum.*to prevent wraparound' THEN 'wraparound'
        WHEN a.query ~ '^vacuum' THEN 'user'
        WHEN a.pid IS NULL THEN NULL
        ELSE 'regular'
    END AS mode,
    CASE WHEN a.pid IS NULL THEN NULL ELSE COALESCE(wait_event_type || '.' || wait_event, 'f') END AS waiting,
    ROUND(100.0 * p.heap_blks_scanned / NULLIF(p.heap_blks_total, 0), 1) AS scanned_pct,
    ROUND(100.0 * p.heap_blks_vacuumed / NULLIF(p.heap_blks_total, 0), 1) AS vacuumed_pct,
    p.index_vacuum_count,
    CASE
        WHEN psat.relid IS NOT NULL AND p.relid IS NOT NULL THEN (SELECT COUNT(*) FROM pg_index WHERE indrelid = psat.relid)
        ELSE NULL
    END AS index_count
FROM pg_stat_all_tables psat
JOIN pg_class ON psat.relid = pg_class.oid
JOIN vacuum_settings ON pg_class.oid = vacuum_settings.oid
FULL OUTER JOIN p ON p.relid = psat.relid AND p.datname = CURRENT_DATABASE()
LEFT JOIN pg_stat_activity a USING (pid)
WHERE psat.relid IS NULL OR autovacuum_vacuum_threshold + (autovacuum_vacuum_scale_factor::NUMERIC * pg_class.reltuples) < psat.n_dead_tup;
```

## Explicação Detalhada

1.  **CTE `table_opts`**:
    * Recupera o OID, nome, esquema e opções de tabelas (`reloptions`) da tabela `pg_class`.

2.  **CTE `vacuum_settings`**:
    * Extrai as configurações de `autovacuum_vacuum_threshold`, `autovacuum_vacuum_scale_factor` e `autovacuum_enabled` das opções de tabela (`relopts`).
    * Usa os valores padrão do sistema se as opções não estiverem definidas na tabela.

3.  **CTE `p`**:
    * Recupera informações de progresso do `VACUUM` da visão `pg_stat_progress_vacuum`.

4.  **Consulta Principal**:
    * Combina as CTEs `table_opts`, `vacuum_settings`, `p` e as tabelas `pg_stat_all_tables` e `pg_stat_activity` para recuperar informações detalhadas sobre o status do `VACUUM`.
    * Calcula o percentual de tuplas mortas (`dead_tup_pct`).
    * Exibe as configurações efetivas de `VACUUM` para cada tabela.
    * Exibe a data da última execução do `VACUUM` (automático ou manual).
    * Exibe o status do `VACUUM` em andamento (`status`).
    * Exibe o PID do processo `VACUUM` em andamento.
    * Exibe o modo do `VACUUM` (wraparound, user, regular).
    * Exibe o evento de espera do processo `VACUUM` em andamento.
    * Exibe o percentual de blocos de heap escaneados e limpos.
    * Exibe o número de `VACUUMs` de índice.
    * Exibe o número de índices na tabela.
    * Filtra as tabelas para incluir apenas aquelas que precisam de `VACUUM` com base nas configurações e no número de tuplas mortas.

## Considerações

* O script fornece informações detalhadas sobre o status do `VACUUM`, que podem ser usadas para monitorar e otimizar o desempenho do `VACUUM`.
* O script considera as configurações de `VACUUM` por tabela, que podem ser diferentes das configurações padrão do sistema.
* O script exibe o progresso do `VACUUM` em andamento, o que pode ser útil para identificar `VACUUMs` de longa duração.
* O script filtra as tabelas para incluir apenas aquelas que precisam de `VACUUM`, o que pode ajudar a priorizar as operações de `VACUUM`.
* O script usa `pg_stat_progress_vacuum` para monitorar o progresso do `VACUUM`, que só está disponível no PostgreSQL 9.6 e posterior.
* O script usa `pg_stat_activity` para obter informações sobre o processo `VACUUM` em andamento.
* O script é muito útil para administradores de banco de dados que desejam monitorar e otimizar o desempenho do `VACUUM` no PostgreSQL.
