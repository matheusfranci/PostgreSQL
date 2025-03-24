# Cálculo de Bloat em Índices B-tree no PostgreSQL

## Descrição

Este script SQL calcula o bloat (excesso de espaço não utilizado) em índices B-tree no PostgreSQL. Ele estima o tamanho ideal dos índices com base em suas estatísticas e compara com o tamanho real para determinar o bloat. Ele também fornece informações sobre o `fillfactor` dos índices.

## Query

```sql
WITH step1 AS (
    SELECT
        i.nspname AS schema_name,
        i.tblname AS table_name,
        i.idxname AS index_name,
        i.reltuples,
        i.relpages,
        i.relam,
        a.attrelid AS table_oid,
        current_setting('block_size')::NUMERIC AS bs,
        fillfactor,
        CASE WHEN version() ~ 'mingw32|64-bit|x86_64|ppc64|ia64|amd64' THEN 8 ELSE 4 END AS maxalign,
        24 AS pagehdr,
        16 AS pageopqdata,
        CASE
            WHEN MAX(COALESCE(s.null_frac, 0)) = 0 THEN 2
            ELSE 2 + ((32 + 8 - 1) / 8)
        END AS index_tuple_hdr_bm,
        SUM((1 - COALESCE(s.null_frac, 0)) * COALESCE(s.avg_width, 1024)) AS nulldatawidth,
        MAX(CASE WHEN a.atttypid = 'pg_catalog.name'::regtype THEN 1 ELSE 0 END) > 0 AS is_na
    FROM pg_attribute AS a
    JOIN (
        SELECT
            nspname, tbl.relname AS tblname, idx.relname AS idxname, idx.reltuples, idx.relpages, idx.relam,
            indrelid, indexrelid, indkey::SMALLINT[] AS attnum,
            COALESCE(SUBSTRING(ARRAY_TO_STRING(idx.reloptions, ' ') FROM 'fillfactor=([0-9]+)')::SMALLINT, 90) AS fillfactor
        FROM pg_index
        JOIN pg_class idx ON idx.oid = pg_index.indexrelid
        JOIN pg_class tbl ON tbl.oid = pg_index.indrelid
        JOIN pg_namespace ON pg_namespace.oid = idx.relnamespace
        WHERE pg_index.indisvalid AND tbl.relkind = 'r' AND idx.relpages > 0
    ) AS i ON a.attrelid = i.indexrelid
    JOIN pg_stats AS s ON
        s.schemaname = i.nspname
        AND (
            (s.tablename = i.tblname AND s.attname = pg_catalog.pg_get_indexdef(a.attrelid, a.attnum, true))
            OR (s.tablename = i.idxname AND s.attname = a.attname)
        )
    JOIN pg_type AS t ON a.atttypid = t.oid
    WHERE a.attnum > 0
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
), step2 AS (
    SELECT
        *,
        (
            index_tuple_hdr_bm + maxalign
            - CASE WHEN index_tuple_hdr_bm % maxalign = 0 THEN maxalign ELSE index_tuple_hdr_bm % maxalign END
            + nulldatawidth + maxalign
            - CASE
                WHEN nulldatawidth = 0 THEN 0
                WHEN nulldatawidth::INTEGER % maxalign = 0 THEN maxalign
                ELSE nulldatawidth::INTEGER % maxalign
            END
        )::NUMERIC AS nulldatahdrwidth
    FROM step1
), step3 AS (
    SELECT
        *,
        COALESCE(1 + CEIL(reltuples / FLOOR((bs - pageopqdata - pagehdr) / (4 + nulldatahdrwidth)::FLOAT)), 0) AS est_pages,
        COALESCE(1 + CEIL(reltuples / FLOOR((bs - pageopqdata - pagehdr) * fillfactor / (100 * (4 + nulldatahdrwidth)::FLOAT))), 0) AS est_pages_ff
    FROM step2
    JOIN pg_am am ON step2.relam = am.oid
    WHERE am.amname = 'btree'
), step4 AS (
    SELECT
        *,
        bs * (relpages)::BIGINT AS real_size,
        bs * (relpages - est_pages)::BIGINT AS extra_size,
        100 * (relpages - est_pages)::FLOAT / relpages AS extra_ratio,
        bs * (relpages - est_pages_ff) AS bloat_size,
        100 * (relpages - est_pages_ff)::FLOAT / relpages AS bloat_ratio
    FROM step3
)
SELECT
    CASE is_na WHEN TRUE THEN 'TRUE' ELSE '' END AS "Is N/A",
    FORMAT(
        $out$%s
(%s)$out$,
        LEFT(index_name, 50) || CASE WHEN LENGTH(index_name) > 50 THEN '…' ELSE '' END,
        COALESCE(NULLIF(schema_name, 'public') || '.', '') || table_name
    ) AS "Index (Table)",
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
    END AS "Bloat",
    CASE
        WHEN (real_size - bloat_size)::NUMERIC >= 0
            THEN '~' || pg_size_pretty((real_size - bloat_size)::NUMERIC)
        ELSE NULL
    END AS "Live",
    fillfactor
FROM step4
ORDER BY real_size DESC NULLS LAST;
```

## Explicação Detalhada

* **`step1` CTE:**
    * Coleta informações sobre índices B-tree, colunas e estatísticas.
    * Calcula o tamanho do cabeçalho da tupla do índice (`index_tuple_hdr_bm`) e o tamanho dos dados (`nulldatawidth`).
    * Determina o `fillfactor` do índice.
* **`step2` CTE:**
    * Calcula o tamanho total da tupla do índice (`nulldatahdrwidth`).
* **`step3` CTE:**
    * Estima o número de páginas necessárias para o índice com base no número de tuplas e no tamanho da tupla (`est_pages`).
    * Estima o número de páginas necessárias levando em consideração o `fillfactor` (`est_pages_ff`).
* **`step4` CTE:**
    * Calcula o tamanho real do índice (`real_size`).
    * Calcula o tamanho do espaço extra (`extra_size`) e a porcentagem de espaço extra (`extra_ratio`).
    * Calcula o tamanho do bloat (`bloat_size`) e a porcentagem de bloat (`bloat_ratio`).
* **Consulta Principal:**
    * Exibe o nome do índice e da tabela associada, o tamanho real, o tamanho do espaço extra, o tamanho do bloat, o tamanho "live" (tamanho real menos bloat) e o `fillfactor`.
    * Formata os tamanhos usando `pg_size_pretty`.
    * Ordena os resultados pelo tamanho real do índice em ordem decrescente.

## Exemplos de Uso

Esta query pode ser usada para:

* Identificar índices B-tree com bloat significativo.
* Monitorar o crescimento do bloat ao longo do tempo.
* Auxiliar na otimização do armazenamento de índices.
* Determinar se é necessário reconstruir índices para reduzir o bloat.

## Considerações

* O bloat em índices pode afetar o desempenho das consultas, pois mais páginas de índice precisam ser lidas.
* Reconstruir índices (`REINDEX`) pode reduzir o bloat
