# Uso de Índices em Tabelas de Usuário no PostgreSQL

## Descrição

Este script SQL recupera o nome da tabela, a porcentagem de vezes que um índice foi usado e o número de linhas na tabela para todas as tabelas de usuário no PostgreSQL onde a soma de varreduras sequenciais e varreduras de índice é maior que zero. Os resultados são ordenados pelo número de linhas na tabela em ordem decrescente.

## Query

```sql
SELECT
    relname,
    100 * idx_scan / (seq_scan + idx_scan) AS percent_of_times_index_used,
    n_live_tup AS rows_in_table
FROM
    pg_stat_user_tables
WHERE
    seq_scan + idx_scan > 0
ORDER BY
    n_live_tup DESC;
```

## Explicação Detalhada

* **`pg_stat_user_tables`**: Esta visão do sistema contém estatísticas sobre tabelas de usuário.
* **`relname`**: O nome da tabela.
* **`idx_scan`**: O número de varreduras de índice realizadas na tabela.
* **`seq_scan`**: O número de varreduras sequenciais realizadas na tabela.
* **`n_live_tup`**: O número de linhas ativas na tabela.
* **`100 * idx_scan / (seq_scan + idx_scan) AS percent_of_times_index_used`**: Calcula a porcentagem de vezes que um índice foi usado na tabela.
* **`WHERE seq_scan + idx_scan > 0`**: Filtra os resultados para incluir apenas tabelas onde pelo menos uma varredura de índice ou varredura sequencial foi realizada.
* **`ORDER BY n_live_tup DESC`**: Ordena os resultados pelo número de linhas na tabela em ordem decrescente.

## Exemplos de Uso

Este script pode ser usado para:

* Identificar tabelas onde os índices são usados com frequência.
* Identificar tabelas onde as varreduras sequenciais são predominantes, o que pode indicar falta de índices ou índices mal otimizados.
* Priorizar a otimização de índices em tabelas grandes.
* Monitorar o desempenho de consultas que usam índices.

## Considerações

* A porcentagem de uso de índices é uma métrica importante para avaliar o desempenho das consultas.
* Uma alta porcentagem de uso de índices indica que as consultas estão aproveitando os índices para recuperar dados com eficiência.
* Uma baixa porcentagem de uso de índices pode indicar que as consultas estão realizando varreduras sequenciais, o que pode ser lento para tabelas grandes.
* O número de linhas na tabela (`n_live_tup`) pode ajudar a determinar se a tabela é grande o suficiente para justificar a otimização de índices.
* A query não considera o tamanho da tabela, apenas o numero de linhas.
* Essa query é útil para identificar tabelas que podem se beneficiar da otimização de índices.
