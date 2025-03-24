# Consultas Mais Lentas no PostgreSQL

## Descrição

Este script SQL recupera as 10 consultas mais lentas do PostgreSQL, ordenadas pelo tempo médio de execução. Ele fornece informações sobre o tempo total de execução, o tempo médio de execução, o número de chamadas e o texto da consulta.

## Query

```sql
SELECT
    total_exec_time,
    mean_exec_time AS avg_ms,
    calls,
    query
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

## Explicação Detalhada

* **`pg_stat_statements`**: Esta visão do sistema contém estatísticas sobre as consultas executadas no servidor PostgreSQL.
* **`total_exec_time`**: O tempo total gasto na execução da consulta (em milissegundos).
* **`mean_exec_time AS avg_ms`**: O tempo médio gasto por execução da consulta (em milissegundos), renomeado para `avg_ms` para maior clareza.
* **`calls`**: O número de vezes que a consulta foi executada.
* **`query`**: O texto da consulta executada.
* **`ORDER BY mean_exec_time DESC`**: Ordena os resultados pelo tempo médio de execução em ordem decrescente, para que as consultas mais lentas apareçam primeiro.
* **`LIMIT 10`**: Limita os resultados às 10 consultas mais lentas.

## Exemplos de Uso

Este script pode ser usado para:

* Identificar as consultas que estão consumindo mais tempo para serem executadas.
* Otimizar consultas para melhorar o desempenho do banco de dados.
* Monitorar o desempenho das consultas ao longo do tempo.
* Diagnosticar problemas de desempenho.

## Considerações

* A extensão `pg_stat_statements` precisa estar instalada e habilitada para que esta query funcione.
* O tempo de execução é medido em milissegundos.
* O tempo médio de execução (`mean_exec_time` ou `avg_ms`) é uma métrica importante para identificar consultas lentas.
* O número de chamadas (`calls`) indica a frequência com que a consulta é executada.
* A query retorna apenas as 10 consultas mais lentas, caso necessite de mais informações, remova a cláusula `LIMIT 10`.
* A identificação de consultas lentas é o primeiro passo para otimizar um banco de dados.
* O resultado da query, indica as consultas que provavelmente necessitam de otimização.
