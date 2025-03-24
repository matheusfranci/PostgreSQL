# Tabelas sem Estatísticas de Colunas no PostgreSQL

## Descrição

Este script SQL identifica tabelas no PostgreSQL que não possuem estatísticas para uma ou mais de suas colunas. Ele também indica se a tabela está vazia e se nunca foi analisada.

## Query

```sql
SELECT
    table_schema,
    table_name,
    (pg_class.relpages = 0) AS is_empty,
    (psut.relname IS NULL OR (psut.last_analyze IS NULL AND psut.last_autoanalyze IS NULL)) AS never_analyzed,
    ARRAY_AGG(column_name::TEXT) AS no_stats_columns
FROM information_schema.columns
JOIN pg_class ON columns.table_name = pg_class.relname
    AND pg_class.relkind = 'r'
JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
    AND nspname = table_schema
LEFT OUTER JOIN pg_stats
    ON table_schema = pg_stats.schemaname
    AND table_name = pg_stats.tablename
    AND column_name = pg_stats.attname
LEFT OUTER JOIN pg_stat_user_tables AS psut
    ON table_schema = psut.schemaname
    AND table_name = psut.relname
WHERE pg_stats.attname IS NULL
    AND table_schema NOT IN ('pg_catalog', 'information_schema')
GROUP BY table_schema, table_name, relpages, psut.relname, last_analyze, last_autoanalyze;
```

## Explicação Detalhada

* **`information_schema.columns`**: Esta visão do sistema contém informações sobre as colunas de todas as tabelas no banco de dados.
* **`pg_class`**: Esta tabela do sistema contém informações sobre relações (tabelas, índices, etc.).
* **`pg_namespace`**: Esta tabela do sistema contém informações sobre esquemas.
* **`pg_stats`**: Esta visão do sistema contém estatísticas sobre colunas de tabelas.
* **`pg_stat_user_tables`**: Esta visão do sistema contém estatísticas sobre tabelas de usuários.
* **`LEFT OUTER JOIN pg_stats ... WHERE pg_stats.attname IS NULL`**: Esta parte da consulta identifica colunas que não possuem estatísticas na tabela `pg_stats`.
* **`(pg_class.relpages = 0) AS is_empty`**: Indica se a tabela está vazia (não possui páginas de dados).
* **`(psut.relname IS NULL OR (psut.last_analyze IS NULL AND psut.last_autoanalyze IS NULL)) AS never_analyzed`**: Indica se a tabela nunca foi analisada (nem manualmente nem automaticamente).
* **`ARRAY_AGG(column_name::TEXT) AS no_stats_columns`**: Agrega os nomes das colunas sem estatísticas em um array.
* **`WHERE table_schema NOT IN ('pg_catalog', 'information_schema')`**: Filtra tabelas dos esquemas `pg_catalog` e `information_schema`.
* **`GROUP BY table_schema, table_name, relpages, psut.relname, last_analyze, last_autoanalyze`**: Agrupa os resultados por esquema, nome da tabela, número de páginas, nome da tabela em `pg_stat_user_tables`, data da última análise manual e data da última análise automática.

## Exemplos de Uso

Esta query pode ser usada para:

* Identificar tabelas que precisam ser analisadas para melhorar o desempenho das consultas.
* Verificar se todas as colunas de uma tabela possuem estatísticas.
* Detectar tabelas vazias que podem ser removidas.

## Considerações

* Estatísticas precisas são essenciais para o otimizador de consultas do PostgreSQL gerar planos de execução eficientes.
* Tabelas sem estatísticas podem resultar em consultas lentas.
* A análise regular de tabelas (`ANALYZE`) garante que as estatísticas estejam atualizadas.
* Tabelas vazias não precisam ser analisadas.

## Recomendações

* Execute `ANALYZE nome_da_tabela;` para gerar estatísticas para uma tabela específica.
* Configure o autovacuum para analisar tabelas automaticamente.
* Monitore regularmente as tabelas sem estatísticas para garantir o desempenho ideal do banco de dados.
