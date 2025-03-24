# Análise de Configurações de Autovacuum e Estado das Tabelas de Usuário no PostgreSQL

## Descrição

Esta query analisa as configurações de autovacuum e o estado das tabelas de usuário no PostgreSQL. Ela fornece informações sobre a última análise manual e automática, o número de linhas, o número de linhas por página, o limite para acionar o `ANALYZE` automático e se a tabela será analisada com base no número de tuplas mortas.

## Query

```sql
WITH table_opts AS (
    SELECT
        pg_class.oid, relname, nspname, array_to_string(reloptions, '') AS relopts
    FROM
        pg_class INNER JOIN pg_namespace ns ON relnamespace = ns.oid
), vacuum_settings AS (
    SELECT
        oid, relname, nspname,
        CASE
            WHEN relopts LIKE '%autovacuum_analyze_threshold%'
                THEN substring(relopts, '.*autovacuum_analyze_threshold=([0-9.]+).*')::integer
            ELSE current_setting('autovacuum_analyze_threshold')::integer
        END AS autovacuum_analyze_threshold,
        CASE
            WHEN relopts LIKE '%autovacuum_analyze_scale_factor%'
                THEN substring(relopts, '.*autovacuum_analyze_scale_factor=([0-9.]+).*')::real
            ELSE current_setting('autovacuum_analyze_scale_factor')::real
        END AS autovacuum_analyze_scale_factor
    FROM
        table_opts
)
SELECT
    vacuum_settings.relname AS table,
    to_char(psut.last_analyze, 'YYYY-MM-DD HH24:MI') AS last_analyze,
    to_char(psut.last_autoanalyze, 'YYYY-MM-DD HH24:MI') AS last_autoanalyze,
    to_char(pg_class.reltuples, '9G999G999G999') AS rowcount,
    to_char(pg_class.reltuples / NULLIF(pg_class.relpages, 0), '999G999.99') AS rows_per_page,
    to_char(autovacuum_analyze_threshold + (autovacuum_analyze_scale_factor::numeric * pg_class.reltuples), '9G999G999G999') AS autovacuum_analyze_threshold,
    CASE
        WHEN autovacuum_analyze_threshold + (autovacuum_analyze_scale_factor::numeric * pg_class.reltuples) < psut.n_dead_tup
        THEN 'yes'
    END AS will_analyze
FROM
    pg_stat_user_tables psut INNER JOIN pg_class ON psut.relid = pg_class.oid
    INNER JOIN vacuum_settings ON pg_class.oid = vacuum_settings.oid
ORDER BY 1;
```

## Explicação Detalhada

A query é dividida em três Common Table Expressions (CTEs):

1.  **`table_opts` CTE:**
    * Recupera as opções de tabelas (`reloptions`) da tabela `pg_class`.
    * Combina com `pg_namespace` para obter o nome do esquema.

2.  **`vacuum_settings` CTE:**
    * Extrai as configurações de `autovacuum_analyze_threshold` e `autovacuum_analyze_scale_factor` das opções da tabela (`relopts`).
    * Se as configurações não estiverem definidas nas opções da tabela, usa as configurações globais do banco de dados.

3.  **Consulta Principal:**
    * Junta as tabelas `pg_stat_user_tables`, `pg_class` e o CTE `vacuum_settings`.
    * Exibe o nome da tabela, a última análise manual e automática, o número de linhas, o número de linhas por página, o limite para acionar o `ANALYZE` automático e se a tabela será analisada.
    * O limite para acionar o `ANALYZE` automático é calculado usando a fórmula: `autovacuum_analyze_threshold + (autovacuum_analyze_scale_factor * rowcount)`.
    * A coluna `will_analyze` indica se a tabela será analisada com base na comparação entre o limite e o número de tuplas mortas (`n_dead_tup`).
    * Formata as datas e números para facilitar a leitura.
    * Ordena os resultados pelo nome da tabela.

## Exemplos de Uso

Esta query pode ser usada para:

* Monitorar o estado das tabelas de usuário em relação ao autovacuum.
* Identificar tabelas que precisam de análise manual ou automática.
* Ajustar as configurações de autovacuum para otimizar o desempenho.
* Diagnosticar problemas relacionados ao autovacuum.

## Considerações

* As configurações de autovacuum podem ser definidas globalmente ou em nível de tabela.
* O `ANALYZE` automático é acionado quando o número de tuplas mortas excede o limite calculado.
* A análise regular das tabelas é importante para manter as estatísticas atualizadas e otimizar o desempenho das consultas.
* A coluna `will_analyze` indica se a tabela será analisada com base no número de tuplas mortas, mas outros fatores (como o tempo desde a última análise) também podem influenciar a decisão do autovacuum.
* A coluna `rows_per_page` pode indicar a densidade de dados na tabela.
* A coluna `rowcount` exibe o número estimado de linhas na tabela.
