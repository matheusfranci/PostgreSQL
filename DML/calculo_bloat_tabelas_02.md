## Descrição

Este script SQL calcula o "bloat" (inchaço) de tabelas no PostgreSQL. O "bloat" se refere ao espaço desperdiçado em tabelas devido a atualizações e exclusões de registros. O script calcula o tamanho real da tabela, o espaço extra usado, a porcentagem de espaço extra, o tamanho do "bloat", a porcentagem de "bloat" e outras métricas relevantes.

## Query

```sql
SELECT
    current_database(),
    schemaname,
    tblname,
    bs * tblpages AS real_size,
    (tblpages - est_tblpages) * bs AS extra_size,
    CASE
        WHEN tblpages - est_tblpages > 0 THEN 100 * (tblpages - est_tblpages) / tblpages::FLOAT
        ELSE 0
    END AS extra_pct,
    fillfactor,
    CASE
        WHEN tblpages - est_tblpages_ff > 0 THEN (tblpages - est_tblpages_ff) * bs
        ELSE 0
    END AS bloat_size,
    CASE
        WHEN tblpages - est_tblpages_ff > 0 THEN 100 * (tblpages - est_tblpages_ff) / tblpages::FLOAT
        ELSE 0
    END AS bloat_pct,
    is_na
    -- , tpl_hdr_size, tpl_data_size, (pst).free_percent + (pst).dead_tuple_percent AS real_frag -- (DEBUG INFO)
FROM (
    SELECT
        CEIL(reltuples / ((bs - page_hdr) / tpl_size)) + CEIL(toasttuples / 4) AS est_tblpages,
        CEIL(reltuples / ((bs - page_hdr) * fillfactor / (tpl_size * 100))) + CEIL(toasttuples / 4) AS est_tblpages_ff,
        tblpages,
        fillfactor,
        bs,
        tblid,
        schemaname,
        tblname,
        heappages,
        toastpages,
        is_na
        -- , tpl_hdr_size, tpl_data_size, pgstattuple(tblid) AS pst -- (DEBUG INFO)
    FROM (
        SELECT
            (4 + tpl_hdr_size + tpl_data_size + (2 * ma) - CASE WHEN tpl_hdr_size % ma = 0 THEN ma ELSE tpl_hdr_size % ma END - CASE WHEN CEIL(tpl_data_size)::INT % ma = 0 THEN ma ELSE CEIL(tpl_data_size)::INT % ma END) AS tpl_size,
            bs - page_hdr AS size_per_block,
            (heappages + toastpages) AS tblpages,
            heappages,
            toastpages,
            reltuples,
            toasttuples,
            bs,
            page_hdr,
            tblid,
            schemaname,
            tblname,
            fillfactor,
            is_na
            -- , tpl_hdr_size, tpl_data_size
        FROM (
            SELECT
                tbl.oid AS tblid,
                ns.nspname AS schemaname,
                tbl.relname AS tblname,
                tbl.reltuples,
                tbl.relpages AS heappages,
                COALESCE(toast.relpages, 0) AS toastpages,
                COALESCE(toast.reltuples, 0) AS toasttuples,
                COALESCE(SUBSTRING(ARRAY_TO_STRING(tbl.reloptions, ' ') FROM 'fillfactor=([0-9]+)')::SMALLINT, 100) AS fillfactor,
                CURRENT_SETTING('block_size')::NUMERIC AS bs,
                CASE WHEN VERSION() ~ 'mingw32' OR VERSION() ~ '64-bit|x86_64|ppc64|ia64|amd64' THEN 8 ELSE 4 END AS ma,
                24 AS page_hdr,
                23 + CASE WHEN MAX(COALESCE(s.null_frac, 0)) > 0 THEN (7 + COUNT(s.attname)) / 8 ELSE 0::INT END + CASE WHEN BOOL_OR(att.attname = 'oid' AND att.attnum < 0) THEN 4 ELSE 0 END AS tpl_hdr_size,
                SUM((1 - COALESCE(s.null_frac, 0)) * COALESCE(s.avg_width, 0)) AS tpl_data_size,
                BOOL_OR(att.atttypid = 'pg_catalog.name'::REGTYPE) OR SUM(CASE WHEN att.attnum > 0 THEN 1 ELSE 0 END) <> COUNT(s.attname) AS is_na
            FROM pg_attribute AS att
            JOIN pg_class AS tbl ON att.attrelid = tbl.oid
            JOIN pg_namespace AS ns ON ns.oid = tbl.relnamespace
            LEFT JOIN pg_stats AS s ON s.schemaname = ns.nspname AND s.tablename = tbl.relname AND s.inherited = FALSE AND s.attname = att.attname
            LEFT JOIN pg_class AS toast ON tbl.reltoastrelid = toast.oid
            WHERE NOT att.attisdropped
                AND tbl.relname NOT LIKE '%pg%'
                AND tbl.relkind IN ('r', 'm')
            GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
            ORDER BY 2, 3
        ) AS s
    ) AS s2
) AS s3
-- WHERE NOT is_na
--  AND tblpages*((pst).free_percent + (pst).dead_tuple_percent)::float4/100 >= 1
ORDER BY bloat_pct DESC;
```

## Explicação Detalhada

1.  **Subconsulta Mais Interna (`s`)**:
    * Recupera informações sobre tabelas (`pg_class`), atributos (`pg_attribute`), estatísticas (`pg_stats`) e namespaces (`pg_namespace`).
    * Calcula o tamanho do cabeçalho da tupla (`tpl_hdr_size`) e o tamanho dos dados da tupla (`tpl_data_size`).
    * Calcula o `fillfactor` (fator de preenchimento) da tabela.
    * Calcula o tamanho do bloco (`bs`) e o alinhamento máximo (`ma`).
    * Determina se a tabela contém colunas `name` ou colunas com estatísticas ausentes (`is_na`).
    * Filtra tabelas do sistema (`tbl.relname NOT LIKE '%pg%'`) e inclui apenas tabelas regulares (`r`) e materialized views (`m`).

2.  **Subconsulta Intermediária (`s2`)**:
    * Calcula o tamanho da tupla (`tpl_size`) e o tamanho por bloco (`size_per_block`).
    * Calcula o número total de páginas da tabela (`tblpages`).
    * Calcula o número estimado de páginas da tabela (`est_tblpages`) com base no número de tuplas e no tamanho da tupla.
    * Calcula o número estimado de páginas da tabela considerando o `fillfactor` (`est_tblpages_ff`).

3.  **Subconsulta Mais Externa (`s3`)**:
    * Calcula o tamanho real da tabela (`real_size`).
    * Calcula o espaço extra usado (`extra_size`) e a porcentagem de espaço extra (`extra_pct`).
    * Calcula o tamanho do "bloat" (`bloat_size`) e a porcentagem de "bloat" (`bloat_pct`).
    * Recupera o nome do banco de dados atual, o nome do esquema e o nome da tabela.

4.  **Consulta Principal**:
    * Seleciona as colunas calculadas e ordena os resultados pela porcentagem de "bloat" em ordem decrescente.
    * Comenta as linhas que usariam `pgstattuple` por ser uma função que pode não estar instalada em todas as instâncias do postgres.

## Considerações

* O script calcula o "bloat" com base no número estimado de páginas e no tamanho real da tabela.
* O script considera o `fillfactor` da tabela ao calcular o "bloat".
* O script exclui tabelas do sistema do cálculo.
* O script usa `pg_stats` para obter informações sobre o tamanho médio das colunas e a fração de valores nulos.
* O script usa `pg_class` para obter informações sobre o número de tuplas e páginas da tabela.
* O script usa `pg_namespace` para obter o nome
