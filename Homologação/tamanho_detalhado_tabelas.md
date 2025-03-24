# Tamanho Detalhado de Tabelas no PostgreSQL

## Descrição

Este script SQL recupera informações detalhadas sobre as tabelas em um banco de dados PostgreSQL. Ele exibe o nome da tabela (incluindo o esquema), a estimativa do número de linhas, o tamanho total, o tamanho da tabela, o tamanho dos índices e o tamanho da TOAST. Ele também calcula a porcentagem que cada componente ocupa do total.

## Query

```sql
WITH data AS (
    SELECT
        c.oid,
        (SELECT spcname FROM pg_tablespace WHERE oid = reltablespace) AS tblspace,
        nspname AS schema_name,
        relname AS table_name,
        c.reltuples AS row_estimate,
        pg_total_relation_size(c.oid) AS total_bytes,
        pg_indexes_size(c.oid) AS index_bytes,
        pg_total_relation_size(reltoastrelid) AS toast_bytes,
        pg_total_relation_size(c.oid) - pg_indexes_size(c.oid) - coalesce(pg_total_relation_size(reltoastrelid), 0) AS table_bytes
    FROM pg_class c
    LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE relkind = 'r' AND nspname <> 'pg_catalog'
), data2 AS (
    SELECT
        NULL::oid AS oid,
        NULL AS tblspace,
        NULL AS schema_name,
        '*** TOTAL ***' AS table_name,
        SUM(row_estimate) AS row_estimate,
        SUM(total_bytes) AS total_bytes,
        SUM(index_bytes) AS index_bytes,
        SUM(toast_bytes) AS toast_bytes,
        SUM(table_bytes) AS table_bytes
    FROM data
    UNION ALL
    SELECT
        NULL::oid AS oid,
        NULL,
        NULL AS schema_name,
        '    tablespace: [' || COALESCE(tblspace, 'pg_default') || ']' AS table_name,
        SUM(row_estimate) AS row_estimate,
        SUM(total_bytes) AS total_bytes,
        SUM(index_bytes) AS index_bytes,
        SUM(toast_bytes) AS toast_bytes,
        SUM(table_bytes) AS table_bytes
    FROM data
    WHERE (SELECT COUNT(DISTINCT COALESCE(tblspace, 'pg_default')) FROM data) > 1 -- don't show this part if there are no custom tablespaces
    GROUP BY tblspace
    UNION ALL
    SELECT NULL::oid, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
    UNION ALL
    SELECT * FROM data
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
    pg_size_pretty(total_bytes) || ' (' || ROUND(
        100 * total_bytes::NUMERIC / NULLIF(SUM(total_bytes) OVER (PARTITION BY (schema_name IS NULL), LEFT(table_name, 3) = '***'), 0),
        2
    )::TEXT || '%)' AS "Total Size",
    pg_size_pretty(table_bytes) || ' (' || ROUND(
        100 * table_bytes::NUMERIC / NULLIF(SUM(table_bytes) OVER (PARTITION BY (schema_name IS NULL), LEFT(table_name, 3) = '***'), 0),
        2
    )::TEXT || '%)' AS "Table Size",
    pg_size_pretty(index_bytes) || ' (' || ROUND(
        100 * index_bytes::NUMERIC / NULLIF(SUM(index_bytes) OVER (PARTITION BY (schema_name IS NULL), LEFT(table_name, 3) = '***'), 0),
        2
    )::TEXT || '%)' AS "Index(es) Size",
    pg_size_pretty(toast_bytes) || ' (' || ROUND(
        100 * toast_bytes::NUMERIC / NULLIF(SUM(toast_bytes) OVER (PARTITION BY (schema_name IS NULL), LEFT(table_name, 3) = '***'), 0),
        2
    )::TEXT || '%)' AS "TOAST Size"
FROM data2
WHERE schema_name IS DISTINCT FROM 'information_schema'
ORDER BY oid IS NULL DESC, total_bytes DESC NULLS LAST;
```

## Explicação Detalhada

* **`data` CTE:**
    * Recupera informações sobre cada tabela da tabela `pg_class` e calcula os tamanhos dos diferentes componentes (total, tabela, índices, TOAST).
    * Inclui o nome do tablespace, o nome do esquema, o nome da tabela e a estimativa do número de linhas.
* **`data2` CTE:**
    * Calcula os tamanhos totais de todos os componentes para todas as tabelas.
    * Adiciona uma linha com o total, linhas com o total por tablespace (se houver mais de um) e uma linha em branco para melhor formatação.
    * Combina os resultados das tabelas individuais e os totais usando `UNION ALL`.
* **Consulta Principal:**
    * Exibe o nome da tabela (incluindo o esquema e o nome do tablespace), a estimativa do número de linhas (formatada para facilitar a leitura), o tamanho total, o tamanho da tabela, o tamanho dos índices e o tamanho da TOAST.
    * Calcula a porcentagem que cada componente ocupa do tamanho total.
    * Formata os tamanhos usando `pg_size_pretty`.
    * Ordena os resultados pelo total (primeiro), totais por tablespace, linha em branco e depois pelo tamanho total em ordem decrescente.
* **Estimativa do número de linhas:**
    * A coluna "Rows" exibe uma estimativa do número de linhas na tabela, formatada usando abreviações (k, M, B, T) para facilitar a leitura.
* **Porcentagens:**
    * As colunas "Total Size", "Table Size", "Index(es) Size" e "TOAST Size" exibem o tamanho de cada componente e a porcentagem que ele ocupa do tamanho total.

## Exemplos de Uso

Esta query pode ser usada para:

* Obter uma visão detalhada do tamanho e composição das tabelas.
* Identificar tabelas que estão consumindo muito espaço em disco.
* Analisar a distribuição do espaço entre diferentes componentes (tabela, índices, TOAST).
* Monitorar o crescimento das tabelas e seus componentes ao longo do tempo.
* Auxiliar na otimização do esquema e desempenho do banco de dados.

## Considerações

* A estimativa do número de linhas (`row_estimate`) pode não ser precisa em tabelas com muitas atualizações ou exclusões recentes.
* A query exclui tabelas do sistema (`nspname <> 'pg_catalog'` e `schema_name IS DISTINCT FROM 'information_schema'`).
* A ordenação coloca os totais no topo da lista e as tabelas maiores no início da lista.
* A formatação dos tamanhos e da estimativa do número de linhas facilita a leitura dos resultados.
* A query fornece informações sobre o uso de espaço por tablespace, se houver mais de um tablespace sendo utilizado.
