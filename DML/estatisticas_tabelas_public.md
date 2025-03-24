# Estatísticas de Tabelas no Esquema Público do PostgreSQL

## Descrição

Esta query fornece estatísticas sobre tabelas no esquema `public` do PostgreSQL. Ela lista o nome da tabela, o tamanho aproximado das linhas, o número de linhas, o número total de índices, o número de índices únicos, o número de índices de coluna única e o número de índices de várias colunas.

## Query

```sql
SELECT
    pg_class.relname,
    pg_size_pretty(pg_class.reltuples::bigint) AS rows_in_bytes,
    pg_class.reltuples AS num_rows,
    COUNT(*) AS total_indexes,
    COUNT(*) FILTER ( WHERE indisunique) AS unique_indexes,
    COUNT(*) FILTER ( WHERE indnatts = 1 ) AS single_column_indexes,
    COUNT(*) FILTER ( WHERE indnatts IS DISTINCT FROM 1 ) AS multi_column_indexes
FROM
    pg_namespace
    LEFT JOIN pg_class ON pg_namespace.oid = pg_class.relnamespace
    LEFT JOIN pg_index ON pg_class.oid = pg_index.indrelid
WHERE
    pg_namespace.nspname = 'public' AND
    pg_class.relkind = 'r'
GROUP BY pg_class.relname, pg_class.reltuples
ORDER BY pg_class.reltuples DESC;
```

## Explicação Detalhada

* `pg_namespace`: Tabela do sistema que contém informações sobre namespaces (esquemas).
* `pg_class`: Tabela do sistema que contém informações sobre relações (tabelas e índices).
* `pg_index`: Tabela do sistema que contém informações sobre índices.
* `pg_class.relname`: Nome da tabela.
* `pg_size_pretty(pg_class.reltuples::bigint) AS rows_in_bytes`: Tamanho aproximado das linhas da tabela em formato legível para humanos.
* `pg_class.reltuples AS num_rows`: Número estimado de linhas na tabela.
* `COUNT(*) AS total_indexes`: Número total de índices na tabela.
* `COUNT(*) FILTER ( WHERE indisunique) AS unique_indexes`: Número de índices únicos na tabela.
* `COUNT(*) FILTER ( WHERE indnatts = 1 ) AS single_column_indexes`: Número de índices de coluna única na tabela.
* `COUNT(*) FILTER ( WHERE indnatts IS DISTINCT FROM 1 ) AS multi_column_indexes`: Número de índices de várias colunas na tabela.
* `pg_namespace.nspname = 'public'`: Filtra para incluir apenas tabelas no esquema `public`.
* `pg_class.relkind = 'r'`: Filtra para incluir apenas relações do tipo tabela.
* `GROUP BY pg_class.relname, pg_class.reltuples`: Agrupa os resultados pelo nome da tabela e pelo número de linhas.
* `ORDER BY pg_class.reltuples DESC`: Ordena os resultados pelo número de linhas em ordem decrescente.

## Exemplos de Uso

Esta query pode ser usada para:

* Obter uma visão geral das tabelas no esquema `public`.
* Identificar tabelas grandes com muitos índices.
* Analisar a distribuição de índices únicos e de várias colunas.
* Auxiliar na otimização do esquema e desempenho do banco de dados.

## Considerações

* O tamanho das linhas (`rows_in_bytes`) é uma estimativa e pode não ser preciso em todos os casos.
* O número de linhas (`reltuples`) é uma estimativa e pode não ser preciso em tabelas com muitas atualizações ou exclusões.
* A query considera apenas índices associados diretamente às tabelas (não índices parciais ou expressões de índice).
* A coluna `indnatts` representa o número de colunas no índice.
