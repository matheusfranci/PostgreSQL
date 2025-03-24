--B-tree indexes bloat (requires pgstattuple; expensive)

--https://github.com/dataegret/pg-utils/tree/master/sql
--pgstattuple extension required
--WARNING: without index name/mask query will read all available indexes which could cause I/O spikes
Certo, vamos analisar e documentar este script SQL que identifica o desperdício de espaço em índices B-tree no PostgreSQL.

**Arquivo Markdown (desperdicio\_espaco\_indices\_btree.md):**

```markdown
# Cálculo de Desperdício de Espaço em Índices B-tree no PostgreSQL

## Descrição

Este script SQL calcula o desperdício de espaço em índices B-tree no PostgreSQL. Ele fornece informações sobre o tamanho do índice, o tamanho da tabela associada, o número de varreduras de índice, a porcentagem de espaço desperdiçado e o tamanho do espaço desperdiçado.

## Query

```sql
WITH data AS (
    SELECT
        schemaname AS schema_name,
        p.relname AS table_name,
        (SELECT spcname FROM pg_tablespace WHERE oid = c_table.reltablespace) AS table_tblspace,
        (SELECT spcname FROM pg_tablespace WHERE oid = c.reltablespace) AS index_tblspace,
        indexrelname AS index_name,
        (
            SELECT (CASE WHEN avg_leaf_density = 'NaN' THEN 0
                ELSE GREATEST(CEIL(index_size * (1 - avg_leaf_density / (COALESCE((SELECT (REGEXP_MATCHES(c.reloptions::TEXT, E'.*fillfactor=(\\d+).*'))[1]), '90')::REAL)))::BIGINT, 0) END)
            FROM pgstatindex(
                CASE WHEN p.indexrelid::regclass::TEXT ~ '\.' THEN p.indexrelid::regclass::TEXT ELSE schemaname || '.' || p.indexrelid::regclass::TEXT END
            )
        ) AS free_space,
        pg_relation_size(p.indexrelid) AS index_size,
        pg_relation_size(p.relid) AS table_size,
        idx_scan
    FROM pg_stat_user_indexes p
    JOIN pg_class c ON p.indexrelid = c.oid
    JOIN pg_class c_table ON p.relid = c_table.oid
    WHERE
        pg_get_indexdef(p.indexrelid) LIKE '%USING btree%'
        AND indexrelname ~ '' -- Substitua '' pelo nome do índice ou padrão de nome desejado
)
SELECT
    COALESCE(NULLIF(schema_name, 'public') || '.', '') || table_name || COALESCE(' [' || table_tblspace || ']', '') AS "Table",
    COALESCE(NULLIF(schema_name, 'public') || '.', '') || index_name || COALESCE(' [' || index_tblspace || ']', '') AS "Index",
    pg_size_pretty(table_size) AS "Table size",
    pg_size_pretty(index_size) AS "Index size",
    idx_scan AS "Index Scans",
    ROUND((free_space * 100 / index_size)::NUMERIC, 1) AS "Wasted, %",
    pg_size_pretty(free_space) AS "Wasted"
FROM data
ORDER BY free_space DESC;
```

## Explicação Detalhada

* **CTE `data`**:
    * Recupera informações sobre índices B-tree da visão `pg_stat_user_indexes`.
    * Calcula o espaço livre (`free_space`) usando a função `pgstatindex`.
    * Calcula o tamanho do índice (`index_size`) e o tamanho da tabela associada (`table_size`) usando `pg_relation_size`.
    * Recupera o número de varreduras de índice (`idx_scan`).
    * Filtra índices que usam B-tree.
    * `indexrelname ~ ''` essa parte do código permite filtrar os resultados por nome de índice, para analisar todos os índices, deixe em branco, para analisar apenas alguns, altere para `indexrelname ~ 'nome_do_indice'` ou para usar expressões regulares.
* **Consulta Principal**:
    * Exibe o nome da tabela e do índice (incluindo o esquema e o tablespace).
    * Exibe o tamanho da tabela e do índice usando `pg_size_pretty`.
    * Exibe o número de varreduras de índice.
    * Calcula e exibe a porcentagem de espaço desperdiçado e o tamanho do espaço desperdiçado.
    * Ordena os resultados pelo espaço desperdiçado em ordem decrescente.

## Exemplos de Uso

* O desperdício de espaço em índices pode afetar o desempenho das consultas, pois mais páginas de índice precisam ser lidas.
* Reconstruir índices (`REINDEX`) pode reduzir o desperdício de espaço, mas pode ser uma operação cara.
* A função `pgstatindex` precisa estar disponível no banco de dados para que a query funcione corretamente.
* O cálculo do espaço livre se baseia no `fillfactor` do índice.
