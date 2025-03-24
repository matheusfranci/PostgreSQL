# Calcular Bloat de Tabelas e Índices no PostgreSQL

## Descrição

Esta query calcula o "bloat" (inchaço) de tabelas e índices no PostgreSQL. O bloat representa o espaço desperdiçado devido a atualizações e exclusões de dados. A query fornece informações sobre o esquema, nome do objeto (tabela ou índice), nível de bloat e espaço desperdiçado.

## Query

```sql
WITH constants AS (
    SELECT current_setting('block_size')::numeric AS bs, 23 AS hdr, 4 AS ma
), bloat_info AS (
    SELECT
        ma,bs,schemaname,tablename,
        (datawidth+(hdr+ma-(case when hdr%ma=0 THEN ma ELSE hdr%ma END)))::numeric AS datahdr,
        (maxfracsum*(nullhdr+ma-(case when nullhdr%ma=0 THEN ma ELSE nullhdr%ma END))) AS nullhdr2
    FROM (
        SELECT
            schemaname, tablename, hdr, ma, bs,
            SUM((1-null_frac)*avg_width) AS datawidth,
            MAX(null_frac) AS maxfracsum,
            hdr+(
                SELECT 1+count(*)/8
                FROM pg_stats s2
                WHERE null_frac<>0 AND s2.schemaname = s.schemaname AND s2.tablename = s.tablename
            ) AS nullhdr
        FROM pg_stats s, constants
        GROUP BY 1,2,3,4,5
    ) AS foo
), table_bloat AS (
    SELECT
        schemaname, tablename, cc.relpages, bs,
        CEIL((cc.reltuples*((datahdr+ma-
            (CASE WHEN datahdr%ma=0 THEN ma ELSE datahdr%ma END))+nullhdr2+4))/(bs-20::float)) AS otta
    FROM bloat_info
    JOIN pg_class cc ON cc.relname = bloat_info.tablename
    JOIN pg_namespace nn ON cc.relnamespace = nn.oid AND nn.nspname = bloat_info.schemaname AND nn.nspname <> 'information_schema'
), index_bloat AS (
    SELECT
        schemaname, tablename, bs,
        COALESCE(c2.relname,'?') AS iname, COALESCE(c2.reltuples,0) AS ituples, COALESCE(c2.relpages,0) AS ipages,
        COALESCE(CEIL((c2.reltuples*(datahdr-12))/(bs-20::float)),0) AS iotta -- very rough approximation, assumes all cols
    FROM bloat_info
    JOIN pg_class cc ON cc.relname = bloat_info.tablename
    JOIN pg_namespace nn ON cc.relnamespace = nn.oid AND nn.nspname = bloat_info.schemaname AND nn.nspname <> 'information_schema'
    JOIN pg_index i ON indrelid = cc.oid
    JOIN pg_class c2 ON c2.oid = i.indexrelid
)
SELECT
    type, schemaname, object_name, bloat, pg_size_pretty(raw_waste) as waste
FROM
(SELECT
    'table' as type,
    schemaname,
    tablename as object_name,
    ROUND(CASE WHEN otta=0 THEN 0.0 ELSE table_bloat.relpages/otta::numeric END,1) AS bloat,
    CASE WHEN relpages < otta THEN '0' ELSE (bs*(table_bloat.relpages-otta)::bigint)::bigint END AS raw_waste
FROM
    table_bloat
    UNION
SELECT
    'index' as type,
    schemaname,
    tablename || '::' || iname as object_name,
    ROUND(CASE WHEN iotta=0 OR ipages=0 THEN 0.0 ELSE ipages/iotta::numeric END,1) AS bloat,
    CASE WHEN ipages < iotta THEN '0' ELSE (bs*(ipages-iotta))::bigint END AS raw_waste
FROM
    index_bloat) bloat_summary
ORDER BY raw_waste DESC, bloat DESC;
```

## Explicação Detalhada

A query é dividida em vários Common Table Expressions (CTEs) para facilitar a leitura e o entendimento:

1.  **`constants` CTE:**
    * Define constantes usadas nos cálculos, como o tamanho do bloco (`bs`), o overhead do cabeçalho da tupla (`hdr`) e o alinhamento múltiplo (`ma`).

2.  **`bloat_info` CTE:**
    * Calcula o tamanho do cabeçalho dos dados (`datahdr`) e o tamanho do cabeçalho dos valores nulos (`nullhdr2`) para cada tabela.
    * Usa a tabela `pg_stats` para obter informações sobre a largura média das colunas e a fração de valores nulos.

3.  **`table_bloat` CTE:**
    * Calcula o número estimado de páginas (`otta`) que a tabela deveria ocupar, com base no número de tuplas e no tamanho do cabeçalho dos dados.
    * Usa as tabelas `pg_class` e `pg_namespace` para obter informações sobre o número de páginas e tuplas da tabela.

4.  **`index_bloat` CTE:**
    * Calcula o número estimado de páginas (`iotta`) que o índice deveria ocupar.
    * Usa as tabelas `pg_class`, `pg_namespace` e `pg_index` para obter informações sobre o número de páginas e tuplas do índice.

5.  **Consulta Principal:**
    * Combina os resultados dos CTEs `table_bloat` e `index_bloat` usando `UNION`.
    * Calcula o nível de bloat (relação entre o número real de páginas e o número estimado de páginas) e o espaço desperdiçado (`raw_waste`).
    * Exibe o esquema, nome do objeto, nível de bloat e espaço desperdiçado.
    * Ordena os resultados pelo espaço desperdiçado em ordem decrescente e, em seguida, pelo nível de bloat em ordem decrescente.

## Exemplos de Uso

Esta query pode ser usada para:

* Identificar tabelas e índices com alto nível de bloat.
* Planejar a manutenção do banco de dados (por exemplo, executar `VACUUM FULL` ou `REINDEX`).
* Otimizar o uso do espaço em disco.
* Monitorar o crescimento do bloat ao longo do tempo.

## Considerações

* O cálculo do bloat é uma estimativa e pode não ser preciso em todos os casos.
* O bloat pode afetar o desempenho das consultas e o uso do espaço em disco.
* A manutenção regular do banco de dados (por exemplo, `VACUUM` e `REINDEX`) pode ajudar a reduzir o bloat.
* Essa consulta pode levar um tempo considerável para ser executada em bancos de dados grandes.
* `VACUUM FULL` bloqueia a tabela e deve ser usado com cautela em ambientes de produção.
* `REINDEX` também bloqueia o índice e deve ser usado com cautela em ambientes de produção.
