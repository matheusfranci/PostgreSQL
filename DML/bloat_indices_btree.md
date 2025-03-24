# Cálculo de Bloat de Índices B-tree no PostgreSQL

## Descrição

Este script SQL calcula o "bloat" (inchaço) de índices B-tree no PostgreSQL, que é a quantidade de espaço desperdiçado devido a páginas de índice não utilizadas. Ele fornece informações sobre o banco de dados, esquema, nome da tabela, nome do índice, porcentagem de bloat, bytes desperdiçados, tamanho do bloat formatado, tamanho total do índice, tamanho do índice formatado, tamanho da tabela, tamanho da tabela formatado e número de varreduras do índice.

## Query

```sql
WITH btree_index_atts AS (
    SELECT nspname, relname, reltuples, relpages, indrelid, relam,
        regexp_split_to_table(indkey::text, ' ')::smallint AS attnum,
        indexrelid AS index_oid
    FROM pg_index
    JOIN pg_class ON pg_class.oid = pg_index.indexrelid
    JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    JOIN pg_am ON pg_class.relam = pg_am.oid
    WHERE pg_am.amname = 'btree'
),
index_item_sizes AS (
    SELECT
        i.nspname, i.relname, i.reltuples, i.relpages, i.relam,
        s.starelid, a.attrelid AS table_oid, index_oid,
        current_setting('block_size')::numeric AS bs,
        CASE
            WHEN version() ~ 'mingw32' OR version() ~ '64-bit' THEN 8
            ELSE 4
        END AS maxalign,
        24 AS pagehdr,
        CASE
            WHEN MAX(COALESCE(s.stanullfrac, 0)) = 0
            THEN 2
            ELSE 6
        END AS index_tuple_hdr,
        SUM((1 - COALESCE(s.stanullfrac, 0)) * COALESCE(s.stawidth, 2048)) AS nulldatawidth
    FROM pg_attribute AS a
    JOIN pg_statistic AS s ON s.starelid = a.attrelid AND s.staattnum = a.attnum
    JOIN btree_index_atts AS i ON i.indrelid = a.attrelid AND a.attnum = i.attnum
    WHERE a.attnum > 0
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
),
index_aligned AS (
    SELECT maxalign, bs, nspname, relname AS index_name, reltuples,
        relpages, relam, table_oid, index_oid,
        (2 + maxalign - CASE
            WHEN index_tuple_hdr % maxalign = 0 THEN maxalign
            ELSE index_tuple_hdr % maxalign
        END + nulldatawidth + maxalign - CASE
            WHEN nulldatawidth::INTEGER % maxalign = 0 THEN maxalign
            ELSE nulldatawidth::INTEGER % maxalign
        END)::NUMERIC AS nulldatahdrwidth, pagehdr
    FROM index_item_sizes AS s1
),
otta_calc AS (
    SELECT bs, nspname, table_oid, index_oid, index_name, relpages, COALESCE(
        CEIL((reltuples * (4 + nulldatahdrwidth)) / (bs - pagehdr::FLOAT)) +
            CASE WHEN am.amname IN ('hash', 'btree') THEN 1 ELSE 0 END, 0
    ) AS otta
    FROM index_aligned AS s2
    LEFT JOIN pg_am am ON s2.relam = am.oid
),
raw_bloat AS (
    SELECT current_database() AS dbname, nspname, c.relname AS table_name, index_name,
        bs * (sub.relpages)::BIGINT AS totalbytes,
        CASE
            WHEN sub.relpages <= otta THEN 0
            ELSE bs * (sub.relpages - otta)::BIGINT
        END AS wastedbytes,
        CASE
            WHEN sub.relpages <= otta
            THEN 0 ELSE bs * (sub.relpages - otta)::BIGINT * 100 / (bs * (sub.relpages)::BIGINT)
        END AS realbloat,
        pg_relation_size(sub.table_oid) AS table_bytes,
        stat.idx_scan AS index_scans
    FROM otta_calc AS sub
    JOIN pg_class AS c ON c.oid = sub.table_oid
    JOIN pg_stat_user_indexes AS stat ON sub.index_oid = stat.indexrelid
)
SELECT dbname AS database_name, nspname AS schema_name, table_name, index_name,
    ROUND(realbloat, 1) AS bloat_pct,
    wastedbytes AS bloat_bytes, pg_size_pretty(wastedbytes::BIGINT) AS bloat_size,
    totalbytes AS index_bytes, pg_size_pretty(totalbytes::BIGINT) AS index_size,
    table_bytes, pg_size_pretty(table_bytes) AS table_size,
    index_scans
FROM raw_bloat
WHERE (realbloat > 50 AND wastedbytes > 50000000)
ORDER BY wastedbytes DESC;
```

## Explicação Detalhada

A query é dividida em várias Common Table Expressions (CTEs) para organizar a lógica:

1.  **`btree_index_atts` CTE:**
    * Recupera informações sobre índices B-tree.
    * Converte as colunas indexadas (`indkey`) em números de atributo (`attnum`).

2.  **`index_item_sizes` CTE:**
    * Calcula o tamanho dos itens do índice, considerando o alinhamento e a largura dos dados.
    * Recupera estatísticas sobre as colunas indexadas (`pg_statistic`).

3.  **`index_aligned` CTE:**
    * Calcula o tamanho total do cabeçalho do item do índice, incluindo o alinhamento.

4.  **`otta_calc` CTE:**
    * Calcula o número de páginas de índice "teóricas" (`otta`) necessárias para armazenar os dados do índice.
    * Considera o tamanho do bloco (`block_size`) e o cabeçalho da página.

5.  **`raw_bloat` CTE:**
    * Calcula o bloat do índice comparando o número real de páginas (`relpages`) com o número de páginas teóricas (`otta`).
    * Calcula o tamanho do bloat em bytes e a porcentagem de bloat.
    * Recupera o tamanho da tabela associada e o número de varreduras do índice.

6.  **Consulta Principal:**
    * Seleciona as informações relevantes sobre o bloat do índice.
    * Filtra os resultados para incluir apenas índices com mais de 50% de bloat e mais de 50 MB de espaço desperdiçado.
    * Ordena os resultados pelo tamanho do bloat em bytes em ordem decrescente.

## Exemplos de Uso

Este script pode ser usado para:

* Identificar índices B-tree com alto bloat.
* Otimizar o espaço em disco removendo ou reconstruindo índices com bloat significativo.
* Melhorar o desempenho de consultas reduzindo o tamanho dos índices.
* Auxiliar na análise e manutenção de índices.
* Identificar indices que podem ser reconstruídos com a opção `REINDEX CONCURRENTLY`.

## Considerações

* O bloat de índices pode ocorrer devido a inserções, atualizações e exclusões frequentes.
* Índices com alto bloat podem ocupar espaço em disco desnecessário e degradar o desempenho de consultas.
* A reconstrução de índices pode reduzir o bloat e melhorar o desempenho.
* A decisão de reconstruir um índice deve ser baseada em uma análise cuidadosa do bloat e do uso do índice.
* Este script é específico para índices B-tree.
* Os filtros utilizados na consulta principal (por exemplo, `realbloat > 50`, `wastedbytes > 50000000`) podem ser ajustados conforme a necessidade.
* A reconstrução de índices é uma operação que pode levar tempo, dependendo do tamanho do índice. É recomendado realizar essa operação em horários de baixa atividade do banco de dados.
* A reconstrução de índices pode ser feita com a opção `CONCURRENTLY`, para evitar o bloqueio de outras operações de banco de dados.
