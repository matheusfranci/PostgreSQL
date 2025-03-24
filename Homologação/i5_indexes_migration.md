# Identificar Índices Não Utilizados ou Redundantes e Gerar Comandos para Migração no PostgreSQL

## Descrição

Este script SQL identifica índices não utilizados ou redundantes no PostgreSQL e gera comandos SQL para removê-los (DROP INDEX CONCURRENTLY) e recriá-los (CREATE INDEX CONCURRENTLY), facilitando a criação de scripts de migração para otimização de índices.

## Query

```sql
WITH unused AS (
    SELECT
        FORMAT('unused (idx_scan: %s)', pg_stat_user_indexes.idx_scan)::TEXT AS reason,
        pg_stat_user_indexes.relname AS table_name,
        pg_stat_user_indexes.schemaname || '.' || indexrelname::TEXT AS index_name,
        pg_stat_user_indexes.idx_scan,
        (COALESCE(n_tup_ins, 0) + COALESCE(n_tup_upd, 0) - COALESCE(n_tup_hot_upd, 0) + COALESCE(n_tup_del, 0)) AS write_activity,
        pg_stat_user_tables.seq_scan,
        pg_stat_user_tables.n_live_tup,
        pg_get_indexdef(pg_index.indexrelid) AS index_def,
        pg_size_pretty(pg_relation_size(pg_index.indexrelid::REGCLASS)) AS index_size,
        pg_index.indexrelid
    FROM pg_stat_user_indexes
    JOIN pg_stat_user_tables
        ON pg_stat_user_indexes.relid = pg_stat_user_tables.relid
    JOIN pg_index
        ON pg_index.indexrelid = pg_stat_user_indexes.indexrelid
    WHERE
        pg_stat_user_indexes.idx_scan = 0
        AND pg_index.indisunique IS FALSE
        AND pg_stat_user_indexes.idx_scan::FLOAT / (COALESCE(n_tup_ins, 0) + COALESCE(n_tup_upd, 0) - COALESCE(n_tup_hot_upd, 0) + COALESCE(n_tup_del, 0) + 1)::FLOAT < 0.01
),
index_data AS (
    SELECT
        *,
        indkey::TEXT AS columns,
        ARRAY_TO_STRING(indclass, ', ') AS opclasses
    FROM pg_index
),
redundant AS (
    SELECT
        i2.indrelid::REGCLASS::TEXT AS table_name,
        i2.indexrelid::REGCLASS::TEXT AS index_name,
        am1.amname AS access_method,
        FORMAT('redundant to index: %I', i1.indexrelid::REGCLASS)::TEXT AS reason,
        pg_get_indexdef(i1.indexrelid) main_index_def,
        pg_get_indexdef(i2.indexrelid) index_def,
        pg_size_pretty(pg_relation_size(i2.indexrelid)) index_size,
        s.idx_scan AS index_usage,
        i2.indexrelid
    FROM index_data AS i1
    JOIN index_data AS i2 ON (i1.indrelid = i2.indrelid AND i1.indexrelid <> i2.indexrelid)
    INNER JOIN pg_opclass op1 ON i1.indclass[0] = op1.oid
    INNER JOIN pg_opclass op2 ON i2.indclass[0] = op2.oid
    INNER JOIN pg_am am1 ON op1.opcmethod = am1.oid
    INNER JOIN pg_am am2 ON op2.opcmethod = am2.oid
    JOIN pg_stat_user_indexes AS s ON s.indexrelid = i2.indexrelid
    WHERE NOT i1.indisprimary
        AND NOT (
            (i1.indisprimary OR i1.indisunique)
            AND (NOT i2.indisprimary OR NOT i2.indisunique)
        )
        AND am1.amname = am2.amname
        AND (
            i2.columns LIKE (i1.columns || '%')
            OR i1.columns = i2.columns
        )
        AND (
            i2.opclasses LIKE (i1.opclasses || '%')
            OR i1.opclasses = i2.opclasses
        )
        AND pg_get_expr(i1.indexprs, i1.indrelid) IS NOT DISTINCT FROM pg_get_expr(i2.indexprs, i2.indrelid)
        AND pg_get_expr(i1.indpred, i1.indrelid) IS NOT DISTINCT FROM pg_get_expr(i2.indpred, i2.indrelid)
),
together AS (
    SELECT reason, table_name, index_name, index_size, index_def, NULL AS main_index_def, indexrelid
    FROM unused
    UNION ALL
    SELECT reason, table_name, index_name, index_size, index_def, main_index_def, indexrelid
    FROM redundant
    WHERE index_usage = 0
),
droplines AS (
    SELECT FORMAT('DROP INDEX CONCURRENTLY %s; -- %s, %s, table %s', MAX(index_name), MAX(index_size), STRING_AGG(reason, ', '), table_name) AS line
    FROM together t1
    GROUP BY table_name, index_name
    ORDER BY table_name, index_name
),
createlines AS (
    SELECT
        REPLACE(
            FORMAT('%s; -- table %s', MAX(index_def), table_name),
            'CREATE INDEX',
            'CREATE INDEX CONCURRENTLY'
        ) AS line
    FROM together t2
    GROUP BY table_name, index_name
    ORDER BY table_name, index_name
)
SELECT '-- DO migration: --' AS run_in_separate_transactions
UNION ALL
SELECT *
FROM droplines
UNION ALL
SELECT ''
UNION ALL
SELECT '-- UNDO migration: --'
UNION ALL
SELECT *
FROM createlines;
```

## Explicação Detalhada

A query é dividida em várias Common Table Expressions (CTEs) para organizar a lógica:

1.  **`unused` CTE:**
    * Identifica índices não utilizados ou pouco utilizados.
    * Filtra índices com `idx_scan = 0` e índices não únicos.
    * Calcula a razão entre varreduras de índice e atividade de escrita na tabela.
    * Recupera informações sobre o índice, a tabela associada e o esquema.

2.  **`index_data` CTE:**
    * Recupera informações sobre todos os índices.
    * Converte as colunas indexadas (`indkey`) e as classes de operadores (`indclass`) em strings legíveis.

3.  **`redundant` CTE:**
    * Identifica índices redundantes comparando índices da mesma tabela.
    * Filtra índices primários e índices únicos que não são redundantes para índices primários.
    * Verifica se os índices usam o mesmo método de acesso, se o índice redundante inclui todas as colunas do índice principal e se as expressões e predicados dos índices são os mesmos.

4.  **`together` CTE:**
    * Combina os resultados dos CTEs `unused` e `redundant`.
    * Inclui índices não utilizados e índices redundantes com uso zero.

5.  **`droplines` CTE:**
    * Gera comandos `DROP INDEX CONCURRENTLY` para os índices identificados no CTE `together`.
    * Agrupa os comandos por tabela e índice.
    * Inclui informações sobre o tamanho do índice e a razão da remoção no comentário do comando.

6.  **`createlines` CTE:**
    * Gera comandos `CREATE INDEX CONCURRENTLY` para os índices identificados no CTE `together`.
    * Agrupa os comandos por tabela e índice.
    * Inclui o nome da tabela no comentário do comando.

7.  **Consulta Principal:**
    * Gera um script de migração completo, incluindo:
        * `-- DO migration: --`: Indica o início dos comandos para aplicar a migração.
        * Comandos `DROP INDEX CONCURRENTLY` gerados no CTE `droplines`.
        * Uma linha em branco para separar as seções.
        * `-- UNDO migration: --`: Indica o início dos comandos para desfazer a migração.
        * Comandos `CREATE INDEX CONCURRENTLY` gerados no CTE `createlines`.

## Exemplos de Uso

Este script pode ser usado para:

* Gerar scripts de migração para otimizar índices em um banco de dados PostgreSQL.
* Remover índices não utilizados ou redundantes para liberar espaço em disco e melhorar o desempenho de operações de escrita.
* Recriar índices removidos, se necessário, para desfazer a migração.

## Considerações

* O script utiliza `DROP INDEX CONCURRENTLY` e `CREATE INDEX CONCURRENTLY` para evitar o bloqueio de outras operações de banco de dados durante a migração.
* Os comandos gerados devem ser revisados cuidadosamente antes de serem executados em um ambiente de produção.
* A decisão de remover ou recriar um índice deve ser baseada em uma análise cuidadosa dos padrões de consulta e da distribuição dos dados.
* Os filtros utilizados nos CTEs `unused` e `redundant` (por exemplo, `idx_scan = 0`, `index_usage = 0`, varreduras de índice e atividade de escrita) podem ser ajustados conforme a necessidade.
* O script assume que a recriação dos índices deve ser feita com a opção `CONCURRENTLY`, para não bloquear a tabela.
* A remoção de índices não utilizados ou redundantes é uma operação segura, mas é sempre bom ter um backup do banco de dados antes de executar qualquer alteração.
