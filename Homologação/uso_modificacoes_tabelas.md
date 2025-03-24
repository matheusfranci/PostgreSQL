# Uso e Modificações de Tabelas no PostgreSQL

## Descrição

Este script SQL recupera informações detalhadas sobre o uso e modificações em tabelas no PostgreSQL. Ele exibe o nome da tabela (incluindo o esquema), a estimativa do número de linhas, o tipo de carga de escrita, o número de tuplas modificadas (inseridas, atualizadas, excluídas), a porcentagem de atualizações HOT e a porcentagem de varreduras sequenciais.

## Query

```sql
WITH data AS (
    SELECT
        s.relname AS table_name,
        s.schemaname AS schema_name,
        (SELECT spcname FROM pg_tablespace WHERE oid = reltablespace) AS tblspace,
        c.reltuples AS row_estimate,
        *,
        CASE WHEN n_tup_upd = 0 THEN NULL ELSE n_tup_hot_upd::NUMERIC / n_tup_upd END AS upd_hot_ratio,
        n_tup_upd + n_tup_del + n_tup_ins AS mod_tup_total
    FROM pg_stat_user_tables s
    JOIN pg_class c ON c.oid = relid
), data2 AS (
    SELECT
        0 AS ord,
        '*** TOTAL ***' AS table_name,
        NULL AS schema_name,
        NULL AS tblspace,
        SUM(row_estimate) AS row_estimate,
        SUM(seq_tup_read) AS seq_tup_read,
        SUM(idx_tup_fetch) AS idx_tup_fetch,
        SUM(n_tup_ins) AS n_tup_ins,
        SUM(n_tup_del) AS n_tup_del,
        SUM(n_tup_upd) AS n_tup_upd,
        SUM(n_tup_hot_upd) AS n_tup_hot_upd,
        AVG(upd_hot_ratio) AS upd_hot_ratio,
        SUM(mod_tup_total) AS mod_tup_total
    FROM data
    UNION ALL
    SELECT
        1 AS ord,
        '    tablespace: [' || COALESCE(tblspace, 'pg_default') || ']' AS table_name,
        NULL AS schema_name,
        NULL,
        SUM(row_estimate) AS row_estimate,
        SUM(seq_tup_read) AS seq_tup_read,
        SUM(idx_tup_fetch) AS idx_tup_fetch,
        SUM(n_tup_ins) AS n_tup_ins,
        SUM(n_tup_del) AS n_tup_del,
        SUM(n_tup_upd) AS n_tup_upd,
        SUM(n_tup_hot_upd) AS n_tup_hot_upd,
        AVG(upd_hot_ratio) AS upd_hot_ratio,
        SUM(mod_tup_total) AS mod_tup_total
    FROM data
    WHERE (SELECT COUNT(DISTINCT COALESCE(tblspace, 'pg_default')) FROM data) > 1
    GROUP BY tblspace
    UNION ALL
    SELECT 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
    UNION ALL
    SELECT 4, table_name, schema_name, tblspace, row_estimate, seq_tup_read, idx_tup_fetch,
        n_tup_ins, n_tup_del, n_tup_upd, n_tup_hot_upd, upd_hot_ratio, mod_tup_total
    FROM data
)
SELECT
    COALESCE(NULLIF(schema_name, 'public') || '.', '') || table_name || COALESCE(' [' || tblspace || ']', '') AS "Table",
    '~' || CASE
        WHEN row_estimate > 10^12 THEN ROUND(row_estimate::NUMERIC / 10^12::NUMERIC, 0)::TEXT || 'T'
        WHEN row_estimate > 10^9 THEN ROUND(row_estimate::NUMERIC / 10^9::NUMERIC, 0)::TEXT || 'B'
        WHEN row_estimate > 10^6 THEN ROUND(row_estimate::NUMERIC / 10^6::NUMERIC, 0)::TEXT || 'M'
        WHEN row_estimate > 10^3 THEN ROUND(row_estimate::NUMERIC / 10^3::NUMERIC, 0)::TEXT || 'k'
        ELSE row_estimate::TEXT
    END AS "Rows",
    (
        WITH ops AS (
            SELECT * FROM data2 d2 WHERE d2.schema_name IS NOT DISTINCT FROM data2.schema_name AND d2.table_name = data2.table_name
        ), ops_ratios(opname, ratio) AS (
            SELECT
                'insert',
                CASE WHEN mod_tup_total > 0 THEN n_tup_ins::NUMERIC / mod_tup_total ELSE 0 END
            FROM ops
            UNION ALL
            SELECT
                'delete',
                CASE WHEN mod_tup_total > 0 THEN n_tup_del::NUMERIC / mod_tup_total ELSE 0 END
            FROM ops
            UNION ALL
            SELECT
                'update',
                CASE WHEN mod_tup_total > 0 THEN n_tup_upd::NUMERIC / mod_tup_total ELSE 0 END
            FROM ops
        )
        SELECT
            CASE
                WHEN ratio > .7 THEN UPPER(opname) || ' ~' || ROUND(100 * ratio, 2)::TEXT || '%'
                ELSE 'Mixed: ' || (
                    SELECT STRING_AGG(UPPER(LEFT(opname, 1)) || ' ~' || ROUND(100 * ratio, 2)::TEXT || '%', ', ' ORDER BY ratio DESC)
                    FROM (SELECT * FROM ops_ratios WHERE ratio > .2) _
                )
            END
        FROM ops_ratios
        ORDER BY ratio DESC
        LIMIT 1
    ) AS "Write Load Type",
    mod_tup_total AS "Tuples modified (I+U+D)",
    n_tup_ins AS "INSERTed",
    n_tup_del AS "DELETEd",
    n_tup_upd AS "UPDATEd",
    ROUND(100 * upd_hot_ratio, 2) AS "HOT-updated, %",
    CASE WHEN seq_tup_read + COALESCE(idx_tup_fetch, 0) > 0 THEN ROUND(100 * seq_tup_read::NUMERIC / (seq_tup_read + COALESCE(idx_tup_fetch, 0)), 2) ELSE 0 END AS "SeqScan, %"
FROM data2
ORDER BY ord, row_estimate DESC;
```

## Explicação Detalhada

* **`data` CTE:**
    * Recupera informações sobre o uso e modificações de tabelas da tabela `pg_stat_user_tables`.
    * Calcula a taxa de atualizações HOT (`upd_hot_ratio`) e o número total de tuplas modificadas (`mod_tup_total`).
* **`data2` CTE:**
    * Calcula os totais de várias métricas para todas as tabelas e para cada tablespace.
    * Adiciona linhas para o total, totais por tablespace (se houver mais de um) e uma linha em branco para melhor formatação.
    * Combina os resultados das tabelas individuais e os totais usando `UNION ALL`.
* **Consulta Principal:**
    * Exibe o nome da tabela (incluindo o esquema e o nome do tablespace), a estimativa do número de linhas, o tipo de carga de escrita, o número de tuplas modificadas, a porcentagem de atualizações HOT e a porcentagem de varreduras sequenciais.
    * Calcula o tipo de carga de escrita com base nas proporções de inserções, atualizações e exclusões.
    * Formata a estimativa do número de linhas usando abreviações (k, M, B, T).
    * Calcula a porcentagem de atualizações HOT e a porcentagem de varreduras sequenciais.
