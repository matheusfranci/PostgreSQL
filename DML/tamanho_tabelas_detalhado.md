# Tamanho Detalhado de Tabelas no PostgreSQL

## Descrição

Esta consulta SQL recupera informações sobre o tamanho de tabelas no PostgreSQL, incluindo o nome do esquema, o nome da tabela, o tamanho total, o tamanho dos dados e o tamanho de dados externos (como índices e TOAST). Ela ordena os resultados pelo tamanho total e tamanho dos dados em ordem decrescente e limita a 10 resultados.

## Query

```sql
SELECT
    schemaname AS table_schema,
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    pg_size_pretty(pg_relation_size(relid)) AS data_size,
    pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) AS external_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY
    pg_total_relation_size(relid) DESC,
    pg_relation_size(relid) DESC
LIMIT 10;
```

## Explicação Detalhada

* **`pg_statio_user_tables`**: Esta visão do sistema contém estatísticas de E/S para tabelas definidas pelo usuário.
* **`schemaname AS table_schema`**: O nome do esquema da tabela.
* **`relname AS table_name`**: O nome da tabela.
* **`pg_size_pretty(pg_total_relation_size(relid)) AS total_size`**: O tamanho total da tabela (incluindo índices, TOAST, etc.) em um formato legível.
* **`pg_size_pretty(pg_relation_size(relid)) AS data_size`**: O tamanho dos dados da tabela em um formato legível.
* **`pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) AS external_size`**: O tamanho dos dados externos (índices, TOAST, etc.) em um formato legível, calculado como a diferença entre o tamanho total e o tamanho dos dados.
* **`ORDER BY pg_total_relation_size(relid) DESC, pg_relation_size(relid) DESC`**: Ordena os resultados pelo tamanho total da tabela em ordem decrescente e, em seguida, pelo tamanho dos dados em ordem decrescente.
* **`LIMIT 10`**: Limita os resultados às 10 maiores tabelas.

## Exemplos de Uso

Este script pode ser usado para:

* Obter informações detalhadas sobre o tamanho das tabelas em um banco de dados PostgreSQL.
* Identificar as tabelas que estão consumindo mais espaço em disco.
* Analisar a distribuição do espaço entre dados e dados externos (índices, TOAST, etc.).
* Auxiliar na otimização do armazenamento de tabelas.

## Considerações

* O tamanho total da tabela (`total_size`) inclui o tamanho dos dados, índices, TOAST e outros elementos associados à tabela.
* O tamanho dos dados (`data_size`) representa o tamanho da tabela em si.
* O tamanho dos dados externos (`external_size`) representa o tamanho dos índices, TOAST e outros elementos associados à tabela, mas não aos dados em si.
* A query retorna apenas as 10 maiores tabelas, caso necessite de mais informações, remova a cláusula `LIMIT 10`.
* A ordenação permite identificar rapidamente as tabelas que estão consumindo mais espaço.
* O uso de `pg_size_pretty` facilita a leitura dos tamanhos das tabelas.
