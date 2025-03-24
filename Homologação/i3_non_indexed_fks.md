# Chaves Estrangeiras com Índices Subótimos ou Ausentes no PostgreSQL

## Descrição

Este script SQL identifica chaves estrangeiras no PostgreSQL que podem estar faltando índices ou que têm índices subótimos. Ele fornece informações sobre o esquema, nome da tabela, nome da chave estrangeira, tipo de problema, tamanho da tabela, número de escritas na tabela, número de varreduras na tabela, nome da tabela pai, tamanho da tabela pai, número de escritas na tabela pai, colunas da chave estrangeira e definição do índice (se existir).

## Query

```sql
WITH fk_actions (code, action) AS (
    VALUES ('a', 'error'),
        ('r', 'restrict'),
        ('c', 'cascade'),
        ('n', 'set null'),
        ('d', 'set default')
),
fk_list AS (
    SELECT
        pg_constraint.oid AS fkoid, conrelid, confrelid AS parentid,
        conname,
        relname,
        nspname,
        fk_actions_update.action AS update_action,
        fk_actions_delete.action AS delete_action,
        conkey AS key_cols
    FROM pg_constraint
    JOIN pg_class ON conrelid = pg_class.oid
    JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
    JOIN fk_actions AS fk_actions_update ON confupdtype = fk_actions_update.code
    JOIN fk_actions AS fk_actions_delete ON confdeltype = fk_actions_delete.code
    WHERE contype = 'f'
),
fk_attributes AS (
    SELECT fkoid, conrelid, attname, attnum
    FROM fk_list
    JOIN pg_attribute ON conrelid = attrelid AND attnum = ANY(key_cols)
    ORDER BY fkoid, attnum
),
fk_cols_list AS (
    SELECT fkoid, ARRAY_AGG(attname) AS cols_list
    FROM fk_attributes
    GROUP BY fkoid
),
index_list AS (
    SELECT
        indexrelid AS indexid,
        pg_class.relname AS indexname,
        indrelid,
        indkey,
        indpred IS NOT NULL AS has_predicate,
        pg_get_indexdef(indexrelid) AS indexdef
    FROM pg_index
    JOIN pg_class ON indexrelid = pg_class.oid
    WHERE indisvalid
),
fk_index_match AS (
    SELECT
        fk_list.*,
        indexid,
        indexname,
        indkey::INT[] AS indexatts,
        has_predicate,
        indexdef,
        ARRAY_LENGTH(key_cols, 1) AS fk_colcount,
        ARRAY_LENGTH(indkey, 1) AS index_colcount,
        ROUND(pg_relation_size(conrelid) / (1024 ^ 2)::NUMERIC) AS table_mb,
        cols_list
    FROM fk_list
    JOIN fk_cols_list USING (fkoid)
    LEFT JOIN index_list ON
        conrelid = indrelid
        AND (indkey::INT2[])[0:(ARRAY_LENGTH(key_cols, 1) - 1)] OPERATOR(pg_catalog.@>) key_cols
),
fk_perfect_match AS (
    SELECT fkoid
    FROM fk_index_match
    WHERE
        (index_colcount - 1) <= fk_colcount
        AND NOT has_predicate
        AND indexdef LIKE '%USING btree%'
),
fk_index_check AS (
    SELECT 'no index' AS issue, *, 1 AS issue_sort
    FROM fk_index_match
    WHERE indexid IS NULL
    UNION ALL
    SELECT 'questionable index' AS issue, *, 2
    FROM fk_index_match
    WHERE
        indexid IS NOT NULL
        AND fkoid NOT IN (SELECT fkoid FROM fk_perfect_match)
),
parent_table_stats AS (
    SELECT
        fkoid,
        tabstats.relname AS parent_name,
        (n_tup_ins + n_tup_upd + n_tup_del + n_tup_hot_upd) AS parent_writes,
        ROUND(pg_relation_size(parentid) / (1024 ^ 2)::NUMERIC) AS parent_mb
    FROM pg_stat_user_tables AS tabstats
    JOIN fk_list ON relid = parentid
),
fk_table_stats AS (
    SELECT
        fkoid,
        (n_tup_ins + n_tup_upd + n_tup_del + n_tup_hot_upd) AS writes,
        seq_scan AS table_scans
    FROM pg_stat_user_tables AS tabstats
    JOIN fk_list ON relid = conrelid
)
SELECT
    nspname AS schema_name,
    relname AS table_name,
    conname AS fk_name,
    issue,
    table_mb,
    writes,
    table_scans,
    parent_name,
    parent_mb,
    parent_writes,
    cols_list,
    indexdef
FROM fk_index_check
JOIN parent_table_stats USING (fkoid)
JOIN fk_table_stats USING (fkoid)
WHERE
    table_mb > 9
    AND (
        writes > 1000
        OR parent_writes > 1000
        OR parent_mb > 10
    )
ORDER BY issue_sort, table_mb DESC, table_name, fk_name;
```

## Explicação Detalhada

A query é dividida em várias Common Table Expressions (CTEs) para organizar a lógica:

1.  **`fk_actions` CTE:**
    * Define as ações de chave estrangeira (por exemplo, `CASCADE`, `SET NULL`).

2.  **`fk_list` CTE:**
    * Recupera informações sobre chaves estrangeiras da tabela `pg_constraint`.
    * Inclui informações sobre as ações de atualização e exclusão da chave estrangeira.

3.  **`fk_attributes` CTE:**
    * Recupera os nomes dos atributos (colunas) da chave estrangeira.

4.  **`fk_cols_list` CTE:**
    * Agrupa os nomes das colunas da chave estrangeira em um array.

5.  **`index_list` CTE:**
    * Recupera informações sobre índices válidos.

6.  **`fk_index_match` CTE:**
    * Combina informações sobre chaves estrangeiras e índices.
    * Verifica se existe um índice que corresponde às colunas da chave estrangeira.
    * Calcula o tamanho da tabela em megabytes.
    * Inclui a lista de colunas da chave estrangeira.

7.  **`fk_perfect_match` CTE:**
    * Identifica chaves estrangeiras com índices perfeitos (ou seja, índices que cobrem todas as colunas da chave estrangeira e não têm predicados).

8.  **`fk_index_check` CTE:**
    * Identifica chaves estrangeiras com índices ausentes ou subótimos.
    * Classifica os problemas como "no index" (índice ausente) ou "questionable index" (índice subótimo).

9.  **`parent_table_stats` CTE:**
    * Recupera estatísticas sobre a tabela pai (tabela referenciada pela chave estrangeira).

10. **`fk_table_stats` CTE:**
    * Recupera estatísticas sobre a tabela com a chave estrangeira.

11. **Consulta Principal:**
    * Combina todas as informações relevantes e filtra os resultados para chaves estrangeiras em tabelas grandes ou com muitas escritas.
    * Ordena os resultados por tipo de problema, tamanho da tabela, nome da tabela e nome da chave estrangeira.

## Exemplos de Uso

Este script pode ser usado para:

* Identificar chaves estrangeiras que podem estar causando problemas de desempenho devido à falta de índices ou índices subótimos.
* Otimizar o desempenho de consultas que envolvem chaves estrangeiras.
* Auxiliar na análise e manutenção do esquema do banco de dados.

## Considerações

* A falta de índices ou índices subótimos em chaves estrangeiras pode levar a varreduras de tabela completas e consultas lentas.
* A criação de índices apropriados pode melhorar significativamente o desempenho de consultas que envolvem chaves estrangeiras.
* A decisão de criar índices deve ser baseada em uma análise cuidadosa dos padrões de consulta e da distribuição dos
