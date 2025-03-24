# Detalhes de Tabelas e Índices no PostgreSQL

## Descrição

Este script SQL recupera informações sobre tabelas e seus índices no PostgreSQL, incluindo esquema, nome da tabela, número de linhas, tamanho da tabela, nome do índice, tamanho do índice, se o índice é único, número de varreduras do índice, tuplas lidas e tuplas buscadas. Ele exclui tabelas dos esquemas `pg_catalog` e `information_schema`.

## Query

```sql
SELECT
    t.schemaname,
    t.tablename,
    c.reltuples::BIGINT AS num_rows,
    pg_size_pretty(pg_relation_size(c.oid)) AS table_size,
    psai.indexrelname AS index_name,
    pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size,
    CASE WHEN i.indisunique THEN 'Y' ELSE 'N' END AS "unique",
    psai.idx_scan AS number_of_scans,
    psai.idx_tup_read AS tuples_read,
    psai.idx_tup_fetch AS tuples_fetched
FROM pg_tables t
LEFT JOIN pg_class c ON t.tablename = c.relname
LEFT JOIN pg_index i ON c.oid = i.indrelid
LEFT JOIN pg_stat_all_indexes psai ON i.indexrelid = psai.indexrelid
WHERE t.schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY 1, 2;
```

## Explicação Detalhada

* **`pg_tables t`**: Esta tabela do sistema contém informações sobre tabelas definidas pelo usuário.
* **`pg_class c`**: Esta tabela do sistema contém informações sobre classes (tabelas, índices, etc.).
* **`pg_index i`**: Esta tabela do sistema contém informações sobre índices.
* **`pg_stat_all_indexes psai`**: Esta visão do sistema contém estatísticas sobre todos os índices.
* **`t.schemaname`**: O nome do esquema da tabela.
* **`t.tablename`**: O nome da tabela.
* **`c.reltuples::BIGINT AS num_rows`**: O número estimado de linhas na tabela (convertido para BIGINT).
* **`pg_size_pretty(pg_relation_size(c.oid)) AS table_size`**: O tamanho da tabela em um formato legível.
* **`psai.indexrelname AS index_name`**: O nome do índice.
* **`pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size`**: O tamanho do índice em um formato legível.
* **`CASE WHEN i.indisunique THEN 'Y' ELSE 'N' END AS "unique"`**: Indica se o índice é único ('Y' para sim, 'N' para não).
* **`psai.idx_scan AS number_of_scans`**: O número de varreduras do índice.
* **`psai.idx_tup_read AS tuples_read`**: O número de tuplas lidas pelo índice.
* **`psai.idx_tup_fetch AS tuples_fetched`**: O número de tuplas buscadas pelo índice.
* **`LEFT JOIN`**: As junções `LEFT JOIN` garantem que todas as tabelas sejam incluídas nos resultados, mesmo que não tenham índices associados.
* **`WHERE t.schemaname NOT IN ('pg_catalog', 'information_schema')`**: Filtra os resultados para excluir tabelas dos esquemas do sistema.
* **`ORDER BY 1, 2`**: Ordena os resultados pelo nome do esquema e pelo nome da tabela.

## Exemplos de Uso

Este script pode ser usado para:

* Obter uma visão geral das tabelas e seus índices em um banco de dados PostgreSQL.
* Identificar tabelas grandes ou índices grandes.
* Analisar o uso de índices (número de varreduras, tuplas lidas e buscadas).
* Identificar índices não utilizados ou pouco utilizados.
* Auxiliar na otimização do desempenho do banco de dados.

## Considerações

* As estatísticas retornadas por `pg_stat_all_indexes` são atualizadas periodicamente pelo coletor de estatísticas do PostgreSQL.
* Os valores retornados representam o número total de operações desde a última reinicialização do coletor de estatísticas.
* A coluna `c.reltuples` fornece uma estimativa do número de linhas na tabela, que pode não ser precisa para tabelas grandes ou com muitas alterações.
* Pode ser interessante consultar outras colunas das tabelas do sistema para uma análise mais completa.
* O uso de `pg_size_pretty` facilita a leitura dos tamanhos das tabelas e índices.
* O uso de `LEFT JOIN` é importante para exibir todas as tabelas, mesmo aquelas sem índices.
