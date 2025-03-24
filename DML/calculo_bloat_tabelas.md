# Cálculo de Bloat em Tabelas no PostgreSQL

## Descrição

Este script SQL calcula o bloat (excesso de espaço não utilizado) em tabelas no PostgreSQL. Ele estima o tamanho ideal das tabelas com base em suas estatísticas e compara com o tamanho real para determinar o bloat. Ele também fornece informações sobre o último `VACUUM` e o `fillfactor` das tabelas.

## Query

```sql
WITH step1 AS (
    SELECT
        tbl.oid tblid,
        ns.nspname AS schema_name,
        tbl.relname AS table_name,
        tbl.reltuples,
        tbl.relpages AS heappages,
        COALESCE(toast.relpages, 0) AS toastpages,
        COALESCE(toast.reltuples, 0) AS toasttuples,
        COALESCE(SUBSTRING(ARRAY_TO_STRING(tbl.reloptions, ' ') FROM '%fillfactor=#"__#"%' FOR '#')::INT2, 100) AS fillfactor,
        current_setting('block_size')::NUMERIC AS bs,
        CASE WHEN version() ~ 'mingw32|64-bit|x86_64|ppc64|ia64|amd64' THEN 8 ELSE 4 END AS ma,
        24 AS page_hdr,
        23 + CASE WHEN MAX(COALESCE(s.null_frac, 0)) > 0 THEN (7 + COUNT(*)) / 8 ELSE 0::INT END
            + CASE WHEN BOOL_OR(att.attname = 'oid' AND att.attnum < 0) THEN 4 ELSE 0 END AS tpl_hdr_size,
        SUM((1 - COALESCE(s.null_frac, 0)) * COALESCE(s.avg_width, 1024)) AS tpl_data_size,
        BOOL_OR(att.atttypid = 'pg_catalog.name'::regtype)
            OR SUM(CASE WHEN att.attnum > 0 THEN 1 ELSE 0 END) <> COUNT(s.attname) AS is_na
    FROM pg_attribute AS att
    JOIN pg_class AS tbl ON att.attrelid = tbl.oid AND tbl.relkind = 'r'
    JOIN pg_namespace AS ns ON ns.oid = tbl.relnamespace
    JOIN pg_stats AS s ON s.schemaname = ns.nspname AND s.tablename = tbl.relname AND NOT s.inherited AND s.attname = att.attname
    LEFT JOIN pg_class AS toast ON tbl.reltoastrelid = toast.oid
    WHERE NOT att.attisdropped AND s.schemaname NOT IN ('pg_catalog', 'information_schema')
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
    ORDER BY 2, 3
), step2 AS (
    SELECT
        *,
        (
            4 + tpl_hdr_size + tpl_data_size + (2 * ma)
            - CASE WHEN tpl_hdr_size % ma = 0 THEN ma ELSE tpl_hdr_size % ma END
            - CASE WHEN CEIL(tpl_data_size)::INT % ma = 0 THEN ma ELSE CEIL(tpl_data_size)::INT % ma END
        ) AS tpl_size,
        bs - page_hdr AS size_per_block,
        (heappages + toastpages) AS tblpages
    FROM step1
), step3 AS (
    SELECT
        *,
        CEIL(reltuples / ((bs - page_hdr) / tpl_size)) + CEIL(toasttuples / 4) AS est_tblpages,
        CEIL(reltuples / ((bs - page_hdr) * fillfactor / (tpl_size * 100))) + CEIL(toasttuples / 4) AS est_tblpages_ff
    FROM step2
), step4 AS (
    SELECT
        *,
        tblpages * bs AS real_size,
        (tblpages - est_tblpages) * bs AS extra_size,
        CASE WHEN tblpages - est_tblpages > 0 THEN 100 * (tblpages - est_tblpages) / tblpages::FLOAT ELSE 0 END AS extra_ratio,
        (tblpages - est_tblpages_ff) * bs AS bloat_size,
        CASE WHEN tblpages - est_tblpages_ff > 0 THEN 100 * (tblpages - est_tblpages_ff) / tblpages::FLOAT ELSE 0 END AS bloat_ratio
    FROM step3
    LEFT JOIN pg_stat_user_tables su ON su.relid = tblid
)
SELECT
    CASE is_na WHEN TRUE THEN 'TRUE' ELSE '' END AS "Is N/A",
    COALESCE(NULLIF(schema_name, 'public') || '.', '') || table_name AS "Table",
    pg_size_pretty(real_size::NUMERIC) AS "Size",
    CASE
        WHEN extra_size::NUMERIC >= 0
            THEN '~' || pg_size_pretty(extra_size::NUMERIC)::TEXT || ' (' || ROUND(extra_ratio::NUMERIC, 2)::TEXT || '%)'
        ELSE NULL
    END AS "Extra",
    CASE
        WHEN bloat_size::NUMERIC >= 0
            THEN '~' || pg_size_pretty(bloat_size::NUMERIC)::TEXT || ' (' || ROUND(bloat_ratio::NUMERIC, 2)::TEXT || '%)'
        ELSE NULL
    END AS "Bloat estimate",
    CASE
        WHEN (real_size - bloat_size)::NUMERIC >= 0
            THEN '~' || pg_size_pretty((real_size - bloat_size)::NUMERIC)
        ELSE NULL
    END AS "Live",
    GREATEST(last_autovacuum, last_vacuum)::TIMESTAMP(0)::TEXT
        || CASE GREATEST(last_autovacuum, last_vacuum)
            WHEN last_autovacuum THEN ' (auto)'
            ELSE ''
        END AS "Last Vaccuum",
    (
        SELECT
            COALESCE(SUBSTRING(ARRAY_TO_STRING(reloptions, ' ') FROM 'fillfactor=([0-9]+)')::SMALLINT, 100)
        FROM pg_class
        WHERE oid = tblid
    ) AS "Fillfactor"
FROM step4
ORDER BY bloat_size DESC NULLS LAST;
```

## Explicação Detalhada

* **`step1` CTE:**
    * Coleta informações sobre tabelas, colunas e estatísticas.
    * Calcula o tamanho do cabeçalho da tupla (`tpl_hdr_size`) e o tamanho dos dados da tupla (`tpl_data_size`).
    * Determina o `fillfactor` da tabela.
* **`step2` CTE:**
    * Calcula o tamanho total da tupla (`tpl_size`) e o tamanho disponível por bloco (`size_per_block`).
    * Calcula o número total de páginas da tabela (`tblpages`).
* **`step3` CTE:**
    * Estima o número de páginas necessárias para a tabela com base no número de tuplas e no tamanho da tupla (`est_tblpages`).
    * Estima o número de páginas necessárias levando em consideração o `fillfactor` (`est_tblpages_ff`).
* **`step4` CTE:**
    * Calcula o tamanho real da tabela (`real_size`).
    * Calcula o tamanho do espaço extra (`extra_size`) e a porcentagem de espaço extra (`extra_ratio`).
    * Calcula o tamanho do bloat (`bloat_size`) e a porcentagem de bloat (`bloat_ratio`).
    * Recupera informações sobre o último `VACUUM`.
* **Consulta Principal:**
    * Exibe o nome da tabela, o tamanho real, o tamanho do espaço extra, o tamanho do bloat, o tamanho "live" (tamanho real menos bloat), o último `VACUUM` e o `fillfactor`.
    * Formata os tamanhos usando `pg_size_pretty`.
    * Ordena os resultados pelo tamanho do bloat em ordem decrescente.

## Exemplos de Uso

Esta query pode ser usada para:

* Identificar tabelas com bloat significativo.
* Monitorar o crescimento do bloat ao longo do tempo.
* Auxiliar na otimização do armazenamento de tabelas.
