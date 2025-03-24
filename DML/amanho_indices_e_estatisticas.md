## Descrição

Este arquivo contém duas queries PostgreSQL para obter informações sobre o tamanho dos índices e estatísticas de uso de tabelas e índices.

## Query 1: Tamanho dos Índices

Esta query lista o nome e o tamanho de todos os índices em bancos de dados de usuário, excluindo índices do sistema.

```sql
SELECT c.relname AS name,
       pg_size_pretty(sum(c.relpages::bigint*8192)::bigint) AS size
FROM pg_class c
LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND n.nspname !~ '^pg_toast'
  AND c.relkind='i'
GROUP BY c.relname
ORDER BY sum(c.relpages) DESC;
```

## Explicação Detalhada

* `pg_class c`: Tabela do sistema que contém informações sobre relações (tabelas e índices).
* `pg_namespace n`: Tabela do sistema que contém informações sobre namespaces (esquemas).
* `c.relname AS name`: Nome do índice.
* `pg_size_pretty(sum(c.relpages::bigint*8192)::bigint) AS size`: Tamanho do índice em formato legível (por exemplo, "MB", "GB").
* `c.relpages`: Número de páginas ocupadas pelo índice.
* `8192`: Tamanho da página em bytes.
* `n.nspname NOT IN ('pg_catalog', 'information_schema')`: Exclui índices dos esquemas do sistema.
* `n.nspname !~ '^pg_toast'`: Exclui índices de tabelas TOAST (armazenamento de valores grandes).
* `c.relkind='i'`: Filtra para incluir apenas índices.
* `GROUP BY c.relname`: Agrupa os resultados pelo nome do índice.
* `ORDER BY sum(c.relpages) DESC`: Ordena os resultados pelo tamanho do índice em ordem decrescente.

## Exemplos de Uso

Esta query pode ser usada para:

* Identificar índices grandes que podem estar ocupando muito espaço em disco.
* Monitorar o crescimento do tamanho dos índices ao longo do tempo.
* Auxiliar na análise e otimização do uso de índices.

## Query 2: Estatísticas de Uso de Tabelas e Índices

Esta query lista estatísticas de uso de tabelas e seus índices, incluindo o número de linhas, tamanho da tabela, nome do índice, tamanho do índice, se o índice é único, número de varreduras do índice, tuplas lidas e tuplas buscadas.

```sql
SELECT
    t.schemaname,
    t.tablename,
    c.reltuples::bigint AS num_rows,
    pg_size_pretty(pg_relation_size(c.oid)) AS table_size,
    psai.indexrelname AS index_name,
    pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size,
    CASE WHEN i.indisunique THEN 'Y' ELSE 'N' END AS "unique",
    psai.idx_scan AS number_of_scans,
    psai.idx_tup_read AS tuples_read,
    psai.idx_tup_fetch AS tuples_fetched
FROM
    pg_tables t
    LEFT JOIN pg_class c ON t.tablename = c.relname
    LEFT JOIN pg_index i ON c.oid = i.indrelid
    LEFT JOIN pg_stat_all_indexes psai ON i.indexrelid = psai.indexrelid
WHERE
    t.schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY 1, 2;
```

## Explicação Detalhada

* `pg_tables t`: Tabela do sistema que contém informações sobre tabelas.
* `pg_class c`: Tabela do sistema que contém informações sobre relações (tabelas e índices).
* `pg_index i`: Tabela do sistema que contém informações sobre índices.
* `pg_stat_all_indexes psai`: Visão do sistema que contém estatísticas de uso de índices.
* `t.schemaname`: Nome do esquema da tabela.
* `t.tablename`: Nome da tabela.
* `c.reltuples::bigint AS num_rows`: Número de linhas na tabela.
* `pg_size_pretty(pg_relation_size(c.oid)) AS table_size`: Tamanho da tabela em formato legível.
* `psai.indexrelname AS index_name`: Nome do índice.
* `pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size`: Tamanho do índice em formato legível.
* `CASE WHEN i.indisunique THEN 'Y' ELSE 'N' END AS "unique"`: Indica se o índice é único.
* `psai.idx_scan AS number_of_scans`: Número de varreduras do índice.
* `psai.idx_tup_read AS tuples_read`: Número de tuplas lidas do índice.
* `psai.idx_tup_fetch AS tuples_fetched`: Número de tuplas buscadas do índice.
* `t.schemaname NOT IN ('pg_catalog', 'information_schema')`: Exclui tabelas dos esquemas do sistema.
* `ORDER BY 1, 2`: Ordena os resultados por esquema e nome da tabela.

## Exemplos de Uso

Esta query pode ser usada para:

* Monitorar o uso de índices e identificar índices não utilizados.
* Avaliar o desempenho de consultas e identificar gargalos.
* Otimizar o uso de índices e o desempenho do banco de dados.
* Identificar tabelas grandes que podem precisar de otimização.
* Analisar a cardinalidade de índices.

## Considerações

* As estatísticas de uso são atualizadas periodicamente pelo coletor de estatísticas do PostgreSQL.
* Índices com baixo número de varreduras podem ser candidatos a remoção.
* Índices com alto número de tuplas lidas e buscadas podem indicar que o índice está sendo usado de forma eficiente.
* A coluna "unique" indica se o índice é único, o que pode afetar o desempenho de consultas.
* O tamanho da tabela e do índice pode influenciar o desempenho de consultas.
