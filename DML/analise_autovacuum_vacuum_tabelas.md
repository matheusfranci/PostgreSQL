# Análise de Configurações de Autovacuum (VACUUM) e Estado das Tabelas de Usuário no PostgreSQL

## Descrição

Esta query analisa as configurações de autovacuum (especificamente o `VACUUM`) e o estado das tabelas de usuário no PostgreSQL. Ela fornece informações sobre a última execução de `VACUUM` manual e automática, o número de linhas, o número de linhas mortas, o número de linhas por página, o limite para acionar o `VACUUM` automático e se a tabela será submetida a `VACUUM` com base no número de tuplas mortas.

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
            WHEN relopts LIKE '%autovacuum_vacuum_threshold%'
                THEN substring(relopts, '.*autovacuum_vacuum_threshold=([0-9.]+).*')::integer
            ELSE current_setting('autovacuum_vacuum_threshold')::integer
        END AS autovacuum_vacuum_threshold,
        CASE
            WHEN relopts LIKE '%autovacuum_vacuum_scale_factor%'
                THEN substring(relopts, '.*autovacuum_vacuum_scale_factor=([0-9.]+).*')::real
            ELSE current_setting('autovacuum_vacuum_scale_factor')::real
        END AS autovacuum_vacuum_scale_factor
    FROM
        table_opts
)
SELECT
    vacuum_settings.relname AS table,
    to_char(psut.last_vacuum, 'YYYY-MM-DD HH24:MI') AS last_vacuum,
    to_char(psut.last_autovacuum, 'YYYY-MM-DD HH24:MI') AS last_autovacuum,
    to_char(pg_class.reltuples, '9G999G999G999') AS rowcount,
    to_char(psut.n_dead_tup, '9G999G999G999') AS dead_rowcount,
    to_char(pg_class.reltuples / NULLIF(pg_class.relpages, 0), '999G999.99') AS rows_per_page,
    to_char(autovacuum_vacuum_threshold + (autovacuum_vacuum_scale_factor::numeric * pg_class.reltuples), '9G999G999G999') AS autovacuum_threshold,
    CASE
        WHEN autovacuum_vacuum_threshold + (autovacuum_vacuum_scale_factor::numeric * pg_class.reltuples) < psut.n_dead_tup
        THEN 'yes'
    END AS will_vacuum
FROM
    pg_stat_user_tables psut INNER JOIN pg_class ON psut.relid = pg_class.oid
    INNER JOIN vacuum_settings ON pg_class.oid = vacuum_settings.oid
ORDER BY psut.n_dead_tup DESC;
```

## Explicação Detalhada

A query é dividida em três Common Table Expressions (CTEs):

1.  **`table_opts` CTE:**
    * Recupera as opções de tabelas (`reloptions`) da tabela `pg_class`.
    * Combina com `pg_namespace` para obter o nome do esquema.

2.  **`vacuum_settings` CTE:**
    * Extrai as configurações de `autovacuum_vacuum_threshold` e `autovacuum_vacuum_scale_factor` das opções da tabela (`relopts`).
    * Se as configurações não estiverem definidas nas opções da tabela, usa as configurações globais do banco de dados.

3.  **Consulta Principal:**
    * Junta as tabelas `pg_stat_user_tables`, `pg_class` e o CTE `vacuum_settings`.
    * Exibe o nome da tabela, a última execução de `VACUUM` manual e automática, o número de linhas, o número de linhas mortas, o número de linhas por página, o limite para acionar o `VACUUM` automático e se a tabela será submetida a `VACUUM`.
    * O limite para acionar o `VACUUM` automático é calculado usando a fórmula: `autovacuum_vacuum_threshold + (autovacuum_vacuum_scale_factor * rowcount)`.
    * A coluna `will_vacuum` indica se a tabela será submetida a `VACUUM` com base na comparação entre o limite e o número de tuplas mortas (`n_dead_tup`).
    * Formata as datas e números para facilitar a leitura.
    * Ordena os resultados pelo número de tuplas mortas (`n_dead_tup`) em ordem decrescente.

## Exemplos de Uso

Esta query pode ser usada para:

* Monitorar o estado das tabelas de usuário em relação ao autovacuum (especificamente o `VACUUM`).
* Identificar tabelas que precisam de `VACUUM` manual ou automático.
* Ajustar as configurações de autovacuum para otimizar o desempenho.
* Diagnosticar problemas relacionados ao autovacuum.
* Identificar tabelas com grande quantidade de tuplas mortas, candidatas a terem o comando VACUUM rodado.

## Considerações

* As configurações de autovacuum podem ser definidas globalmente ou em nível de tabela.
* O `VACUUM` automático é acionado quando o número de tuplas mortas excede o limite calculado.
* A execução regular de `VACUUM` é importante para recuperar espaço em disco e manter o desempenho do banco de dados.
* A coluna `will_vacuum` indica se a tabela será submetida a `VACUUM` com base no número de tuplas mortas, mas outros fatores (como o tempo desde o último `VACUUM`) também podem influenciar a decisão do autovacuum.
* A coluna `rows_per_page` pode indicar a densidade de dados na tabela.
* A coluna `dead_rowcount` exibe o número de linhas que foram marcadas para exclusão, mas ainda não foram removidas fisicamente.
