# Índices Redundantes com Suporte a Chaves Estrangeiras no PostgreSQL

## Descrição

Este script SQL identifica índices redundantes no PostgreSQL, considerando se eles são usados para suporte a chaves estrangeiras. Ele classifica os índices redundantes e fornece informações detalhadas sobre eles, incluindo esquema, nome da tabela, tamanho da tabela, nome do índice, método de acesso, índices aos quais são redundantes, definições dos índices principais, tamanho dos índices principais, definição do índice redundante, tamanho do índice redundante, uso do índice e se ele suporta chaves estrangeiras.

## Query

```sql
WITH fk_indexes AS (
    SELECT
        n.nspname AS schema_name,
        ci.relname AS index_name,
        cr.relname AS table_name,
        (confrelid::regclass)::TEXT AS fk_table_ref,
        ARRAY_TO_STRING(indclass, ', ') AS opclasses
    FROM pg_index i
    JOIN pg_class ci ON ci.oid = i.indexrelid AND ci.relkind = 'i'
    JOIN pg_class cr ON cr.oid = i.indrelid AND cr.relkind = 'r'
    JOIN pg_namespace n ON n.oid = ci.relnamespace
    JOIN pg_constraint cn ON cn.conrelid = cr.oid
    LEFT JOIN pg_stat_user_indexes si ON si.indexrelid = i.indexrelid
    WHERE
        contype = 'f'
        AND i.indisunique IS FALSE
        AND conkey IS NOT NULL
        AND ci.relpages > 0
        AND si.idx_scan < 10
),
index_data AS (
    SELECT
        *,
        (SELECT STRING_AGG(LPAD(i, 3, '0'), ' ') FROM UNNEST(STRING_TO_ARRAY(indkey::TEXT, ' ')) i) AS columns,
        ARRAY_TO_STRING(indclass, ', ') AS opclasses
    FROM pg_index i
    JOIN pg_class ci ON ci.oid = i.indexrelid AND ci.relkind = 'i'
    WHERE indisvalid = TRUE AND ci.relpages > 0
),
redundant_indexes AS (
    SELECT
        i2.indexrelid AS index_id,
        tnsp.nspname AS schema_name,
        trel.relname AS table_name,
        pg_relation_size(trel.oid) AS table_size_bytes,
        irel.relname AS index_name,
        am1.amname AS access_method,
        (i1.indexrelid::regclass)::TEXT AS reason,
        i1.indexrelid AS reason_index_id,
        pg_get_indexdef(i1.indexrelid) main_index_def,
        pg_size_pretty(pg_relation_size(i1.indexrelid)) main_index_size,
        pg_get_indexdef(i2.indexrelid) index_def,
        pg_relation_size(i2.indexrelid) AS index_size_bytes,
        s.idx_scan AS index_usage,
        QUOTE_IDENT(tnsp.nspname) AS formated_schema_name,
        COALESCE(NULLIF(QUOTE_IDENT(tnsp.nspname), 'public') || '.', '') || QUOTE_IDENT(irel.relname) AS formated_index_name,
        QUOTE_IDENT(trel.relname) AS formated_table_name,
        COALESCE(NULLIF(QUOTE_IDENT(tnsp.nspname), 'public') || '.', '') || QUOTE_IDENT(trel.relname) AS formated_relation_name,
        i2.opclasses
    FROM index_data AS i1
    JOIN index_data AS i2 ON (i1.indrelid = i2.indrelid AND i1.indexrelid <> i2.indexrelid)
    INNER JOIN pg_opclass op1 ON i1.indclass[0] = op1.oid
    INNER JOIN pg_opclass op2 ON i2.indclass[0] = op2.oid
    INNER JOIN pg_am am1 ON op1.opcmethod = am1.oid
    INNER JOIN pg_am am2 ON op2.opcmethod = am2.oid
    JOIN pg_stat_user_indexes AS s ON s.indexrelid = i2.indexrelid
    JOIN pg_class AS trel ON trel.oid = i2.indrelid
    JOIN pg_namespace AS tnsp ON trel.relnamespace = tnsp.oid
    JOIN pg_class AS irel ON irel.oid = i2.indexrelid
    WHERE NOT i2.indisprimary
        AND NOT (i2.indisunique AND NOT i1.indisprimary)
        AND am1.amname = am2.amname
        AND i1.columns LIKE (i2.columns || '%')
        AND i1.opclasses LIKE (i2.opclasses || '%')
        AND pg_get_expr(i1.indexprs, i1.indrelid) IS NOT DISTINCT FROM pg_get_expr(i2.indexprs, i2.indrelid)
        AND pg_get_expr(i1.indpred, i1.indrelid) IS NOT DISTINCT FROM pg_get_expr(i2.indpred, i2.indrelid)
),
redundant_indexes_fk AS (
    SELECT
        ri.*,
        (SELECT COUNT(1) FROM fk_indexes fi WHERE fi.fk_table_ref = ri.table_name AND fi.opclasses LIKE (ri.opclasses || '%')) > 0 AS supports_fk
    FROM redundant_indexes ri
),
redundant_indexes_tmp_num AS (
    SELECT
        ROW_NUMBER() OVER () AS num,
        rig.*
    FROM redundant_indexes_fk rig
    ORDER BY index_id
),
redundant_indexes_tmp_cut AS (
    SELECT
        ri1.*,
        ri2.num AS r_num
    FROM redundant_indexes_tmp_num ri1
    LEFT JOIN redundant_indexes_tmp_num ri2 ON ri2.reason_index_id = ri1.index_id AND ri1.reason_index_id = ri2.index_id
    WHERE ri1.num < ri2.num OR ri2.num IS NULL
),
redundant_indexes_cut_grouped AS (
    SELECT DISTINCT(num), *
    FROM redundant_indexes_tmp_cut
    ORDER BY index_size_bytes DESC
),
redundant_indexes_grouped AS (
    SELECT DISTINCT(num), *
    FROM redundant_indexes_tmp_cut
    ORDER BY index_size_bytes DESC
)
SELECT
    schema_name,
    table_name,
    table_size_bytes,
    index_name,
    access_method,
    STRING_AGG(DISTINCT reason, ', ') AS redundant_to,
    STRING_AGG(main_index_def, ', ') AS main_index_def,
    STRING_AGG(main_index_size, ', ') AS main_index_size,
    index_def,
    index_size_bytes,
    index_usage,
    supports_fk
FROM redundant_indexes_cut_grouped
GROUP BY
    index_id,
    schema_name,
    table_name,
    table_size_bytes,
    index_name,
    access_method,
    index_def,
    index_size_bytes,
    index_usage,
    supports_fk
ORDER BY index_size_bytes DESC;
```

## Explicação Detalhada

A query é dividida em várias Common Table Expressions (CTEs) para organizar a lógica:

1.  **`fk_indexes` CTE:**
    * Recupera informações sobre índices que suportam chaves estrangeiras.
    * Filtra índices não únicos e com uso baixo (`idx_scan < 10`).

2.  **`index_data` CTE:**
    * Recupera informações sobre todos os índices válidos.
    * Converte as colunas indexadas (`indkey`) e as classes de operadores (`indclass`) em strings legíveis.

3.  **`redundant_indexes` CTE:**
    * Identifica índices redundantes comparando índices da mesma tabela.
    * Filtra índices primários e índices únicos que não são redundantes para índices primários.
    * Verifica se os índices usam o mesmo método de acesso, se o índice redundante inclui todas as colunas do índice principal e se as expressões e predicados dos índices são os mesmos.
