# Tamanho de Tabelas e Índices e Atualizações no PostgreSQL

## Descrição

Este script SQL recupera o nome do esquema, o nome da tabela, o tamanho total da tabela (incluindo índices), o tamanho da tabela, o tamanho dos índices, o número de atualizações e o número de atualizações HOT (Heap-Only Tuple) para as 10 tabelas de usuário com o maior número de atualizações.

## Query

```sql
SELECT
    schemaname,
    relname,
    pg_size_pretty(pg_total_relation_size(relname::REGCLASS)) AS full_size,
    pg_size_pretty(pg_relation_size(relname::REGCLASS)) AS table_size,
    pg_size_pretty(pg_total_relation_size(relname::REGCLASS) - pg_relation_size(relname::REGCLASS)) AS index_size,
    n_tup_upd,
    n_tup_hot_upd
FROM
    pg_stat_user_tables
ORDER BY
    n_tup_upd DESC
LIMIT 10;
```

## Explicação Detalhada

* **`pg_stat_user_tables`**: Esta visão do sistema contém estatísticas sobre tabelas de usuário.
* **`schemaname`**: O nome do esquema da tabela.
* **`relname`**: O nome da tabela.
* **`pg_total_relation_size(relname::REGCLASS)`**: Calcula o tamanho total da tabela, incluindo índices e TOAST.
* **`pg_relation_size(relname::REGCLASS)`**: Calcula o tamanho da tabela (dados) apenas.
* **`pg_total_relation_size(relname::REGCLASS) - pg_relation_size(relname::REGCLASS)`**: Calcula o tamanho total dos índices da tabela.
* **`pg_size_pretty(...)`**: Formata o tamanho em bytes em um formato legível para humanos (por exemplo, "10 MB").
* **`n_tup_upd`**: O número de tuplas atualizadas na tabela.
* **`n_tup_hot_upd`**: O número de tuplas atualizadas usando HOT (Heap-Only Tuple).
* **`ORDER BY n_tup_upd DESC`**: Ordena os resultados pelo número de atualizações em ordem decrescente.
* **`LIMIT 10`**: Limita os resultados às 10 tabelas com o maior número de atualizações.

## Exemplos de Uso

Este script pode ser usado para:

* Identificar tabelas com alta atividade de atualização.
* Analisar o tamanho de tabelas e índices.
* Avaliar o impacto das atualizações no tamanho da tabela e dos índices.
* Monitorar o uso de atualizações HOT, que podem melhorar o desempenho de atualizações frequentes.

## Considerações

* Atualizações HOT são atualizações que modificam tuplas na mesma página de heap, sem precisar atualizar os índices.
* O uso de atualizações HOT pode reduzir a sobrecarga de E/S e melhorar o desempenho de atualizações frequentes.
* Tabelas com um alto número de atualizações podem se beneficiar da otimização de índices e do uso de atualizações HOT.
* A query lista as 10 tabelas com o maior número de atualizações.
* Essa query é útil para identificar tabelas com alta atividade de escrita.
