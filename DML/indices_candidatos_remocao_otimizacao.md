# Índices Candidatos a Remoção ou Otimização no PostgreSQL

## Descrição

Este script SQL identifica índices no PostgreSQL que podem ser candidatos a remoção ou otimização com base em padrões de uso e características. Ele classifica os índices em diferentes grupos com base em sua utilização, tamanho e tipo, fornecendo informações sobre o esquema, nome da tabela, nome do índice, porcentagem de varreduras de índice, varreduras por escrita, tamanho do índice e tamanho da tabela.

## Query

```sql
WITH table_scans AS (
    SELECT relid,
        tables.idx_scan + tables.seq_scan AS all_scans,
        (tables.n_tup_ins + tables.n_tup_upd + tables.n_tup_del) AS writes,
        pg_relation_size(relid) AS table_size
    FROM pg_stat_user_tables AS tables
),
all_writes AS (
    SELECT SUM(writes) AS total_writes
    FROM table_scans
),
indexes AS (
    SELECT idx_stat.relid, idx_stat.indexrelid,
        idx_stat.schemaname, idx_stat.relname AS tablename,
        idx_stat.indexrelname AS indexname,
        idx_stat.idx_scan,
        pg_relation_size(idx_stat.indexrelid) AS index_bytes,
        indexdef ~* 'USING btree' AS idx_is_btree
    FROM pg_stat_user_indexes AS idx_stat
    JOIN pg_index
        USING (indexrelid)
    JOIN pg_indexes AS indexes
        ON idx_stat.schemaname = indexes.schemaname
        AND idx_stat.relname = indexes.tablename
        AND idx_stat.indexrelname = indexes.indexname
    WHERE pg_index.indisunique = FALSE
),
index_ratios AS (
SELECT schemaname, tablename, indexname,
    idx_scan, all_scans,
    ROUND((CASE WHEN all_scans = 0 THEN 0.0::NUMERIC
        ELSE idx_scan::NUMERIC / all_scans * 100 END), 2) AS index_scan_pct,
    writes,
    ROUND((CASE WHEN writes = 0 THEN idx_scan::NUMERIC ELSE idx_scan::NUMERIC / writes END), 2)
        AS scans_per_write,
    pg_size_pretty(index_bytes) AS index_size,
    pg_size_pretty(table_size) AS table_size,
    idx_is_btree, index_bytes
    FROM indexes
    JOIN table_scans
    USING (relid)
),
index_groups AS (
SELECT 'Never Used Indexes' AS reason, *, 1 AS grp
FROM index_ratios
WHERE
    idx_scan = 0
    AND idx_is_btree
UNION ALL
SELECT 'Low Scans, High Writes' AS reason, *, 2 AS grp
FROM index_ratios
WHERE
    scans_per_write <= 1
    AND index_scan_pct < 10
    AND idx_scan > 0
    AND writes > 100
    AND idx_is_btree
UNION ALL
SELECT 'Seldom Used Large Indexes' AS reason, *, 3 AS grp
FROM index_ratios
WHERE
    index_scan_pct < 5
    AND scans_per_write > 1
    AND idx_scan > 0
    AND idx_is_btree
    AND index_bytes > 100000000
UNION ALL
SELECT 'High-Write Large Non-Btree' AS reason, index_ratios.*, 4 AS grp
FROM index_ratios, all_writes
WHERE
    (writes::NUMERIC / (total_writes + 1)) > 0.02
    AND NOT idx_is_btree
    AND index_bytes > 100000000
ORDER BY grp, index_bytes DESC
)
SELECT reason, schemaname, tablename, indexname,
    index_scan_pct, scans_per_write, index_size, table_size
FROM index_groups;
```

## Explicação Detalhada

A query é dividida em várias Common Table Expressions (CTEs) para organizar a lógica:

1.  **`table_scans` CTE:**
    * Recupera informações sobre varreduras de tabelas e contagem de escritas da tabela `pg_stat_user_tables`.
    * Calcula o número total de varreduras (`all_scans`) e o número total de escritas (`writes`).
    * Recupera o tamanho da tabela (`table_size`).

2.  **`all_writes` CTE:**
    * Calcula o número total de escritas em todas as tabelas.

3.  **`indexes` CTE:**
    * Recupera informações sobre índices da tabela `pg_stat_user_indexes`.
    * Filtra índices que não são únicos.
    * Recupera o tamanho do índice (`index_bytes`).
    * Identifica se o índice é do tipo B-tree (`idx_is_btree`).

4.  **`index_ratios` CTE:**
    * Calcula a porcentagem de varreduras de índice (`index_scan_pct`) e o número de varreduras por escrita (`scans_per_write`).
    * Recupera informações sobre o esquema, nome da tabela, nome do índice, tamanho do índice e tamanho da tabela.

5.  **`index_groups` CTE:**
    * Classifica os índices em diferentes grupos com base em seus padrões de uso e características:
        * **`Never Used Indexes`**: Índices B-tree que nunca foram usados (`idx_scan = 0`).
        * **`Low Scans, High Writes`**: Índices B-tree com poucas varreduras, muitas escritas e baixa porcentagem de varreduras de índice.
        * **`Seldom Used Large Indexes`**: Índices B-tree grandes que são raramente usados e possuem poucas varreduras por escrita.
        * **`High-Write Large Non-Btree`**: Índices grandes que não são B-tree e pertencem a tabelas com muitas escritas.
    * Atribui um número de grupo (`grp`) a cada categoria.
    * Ordena os resultados por grupo e tamanho do índice.

6.  **Consulta Principal:**
    * Seleciona as informações relevantes de cada grupo: razão, esquema, nome da tabela, nome do índice, porcentagem de varreduras de índice, varreduras por escrita, tamanho do índice e tamanho da tabela.
    * Ordena os resultados pelo número do grupo e tamanho do índice.

## Exemplos de Uso

Este script pode ser usado para:

* Identificar índices que podem ser candidatos a remoção ou otimização.
* Otimizar o desempenho do banco de dados reduzindo a sobrecarga de índices desnecessários.
* Auxiliar na análise e manutenção de índices.

## Considerações

* A classificação dos índices em diferentes grupos permite priorizar a análise e ação.
* Índices não utilizados ou pouco utilizados podem ocupar espaço desnecessário e degradar o desempenho de operações de escrita.
* Índices com muitas escritas e poucas varreduras podem indicar que a sobrecarga de manutenção do índice supera os benefícios de leitura.
* Índices grandes e raramente usados podem ser candidatos a remoção ou reconstrução.
* Índices não B-tree em tabelas com muitas escritas podem ser candidatos a otimização ou substituição por índices B-tree.
* A decisão de remover ou otimizar um índice deve ser baseada em uma análise cuidadosa dos padrões de consulta e da distribuição dos dados.
* Os filtros utilizados (scans\_per\_write, index\_scan\_pct, idx\_scan, writes, index\_bytes, idx\_is\_btree, writes::NUMERIC / (total\_writes + 1)) podem ser ajustados conforme a necessidade.
