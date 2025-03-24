# Tamanho Total de Relação no PostgreSQL

## Descrição

Este script SQL calcula o tamanho total de uma relação (tabela, índice, etc.) no PostgreSQL e formata o resultado em um formato legível para humanos.

## Query

```sql
SELECT pg_size_pretty(pg_total_relation_size('rel'));
```

## Explicação Detalhada

* **`pg_total_relation_size('rel')`**: Esta função do PostgreSQL calcula o tamanho total de uma relação, incluindo o tamanho da tabela principal, índices e TOAST (The Oversized Attribute Storage Technique).
    * `'rel'` deve ser substituído pelo nome da relação (tabela, índice, etc.) que você deseja analisar.
* **`pg_size_pretty(...)`**: Esta função formata o tamanho em bytes retornado por `pg_total_relation_size()` em um formato legível para humanos, como "10 MB" ou "2 GB".

## Exemplos de Uso

1.  Para obter o tamanho total da tabela chamada `clientes`:

    ```sql
    SELECT pg_size_pretty(pg_total_relation_size('clientes'));
    ```

2.  Para obter o tamanho total do índice chamado `clientes_pkey`:

    ```sql
    SELECT pg_size_pretty(pg_total_relation_size('clientes_pkey'));
    ```

## Considerações

* Certifique-se de substituir `'rel'` pelo nome correto da relação que você deseja analisar.
* A função `pg_size_pretty()` facilita a leitura do tamanho da relação, especialmente para relações grandes.
* O tamanho total inclui o tamanho da tabela principal, índices e TOAST.
* Se a relação não existir, a função `pg_total_relation_size()` retornará um erro.
* Esta query é muito útil para entender o tamanho das tabelas e indexes do banco de dados.
