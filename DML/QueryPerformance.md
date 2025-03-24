# Análise de Desempenho de Queries no PostgreSQL

## Descrição

Esta query analisa o desempenho de queries executadas no PostgreSQL, utilizando a extensão `pg_stat_statements`. Ela fornece informações sobre o tempo total de execução, o tempo médio por execução, o número de chamadas, o desvio padrão do tempo de execução, o número de linhas retornadas e a taxa de acertos no cache.

## Query

```sql
SELECT query,
       calls,
       total_time,
       total_time / calls AS time_per,
       stddev_time,
       rows,
       rows / calls AS rows_per,
       100.0 * shared_blks_hit / NULLIF(shared_blks_hit + shared_blks_read, 0) AS hit_percent
FROM pg_stat_statements
WHERE query NOT SIMILAR TO '%pg_%'
  AND calls > 500
ORDER BY time_per DESC
LIMIT 20;
```

## Explicação Detalhada

* `pg_stat_statements`: Esta visão do sistema fornece estatísticas sobre queries executadas no servidor PostgreSQL.
* `query`: O texto da query executada.
* `calls`: O número de vezes que a query foi executada.
* `total_time`: O tempo total gasto na execução da query (em milissegundos).
* `time_per`: O tempo médio gasto por execução da query (em milissegundos).
* `stddev_time`: O desvio padrão do tempo de execução da query.
* `rows`: O número total de linhas retornadas pela query.
* `rows_per`: O número médio de linhas retornadas por execução da query.
* `hit_percent`: A porcentagem de blocos de cache acessados com sucesso (taxa de acertos).
* `WHERE query NOT SIMILAR TO '%pg_%'`: Exclui queries do sistema (que começam com 'pg\_').
* `WHERE calls > 500`: Filtra para incluir apenas queries que foram executadas mais de 500 vezes.
* `ORDER BY time_per DESC`: Ordena os resultados pelo tempo médio por execução em ordem decrescente.
* `LIMIT 20`: Limita os resultados às 20 queries com o maior tempo médio por execução.
* `NULLIF(shared_blks_hit + shared_blks_read, 0)`: Evita divisão por zero se não houver leituras de blocos.

## Exemplos de Uso

Esta query pode ser usada para:

* Identificar queries lentas que estão afetando o desempenho do banco de dados.
* Analisar o tempo médio de execução de queries frequentes.
* Avaliar a eficácia do cache do banco de dados.
* Otimizar queries para melhorar o desempenho.
* Monitorar o desempenho de queries ao longo do tempo.

## Considerações

* A extensão `pg_stat_statements` precisa estar instalada e habilitada para que esta query funcione.
* O tempo de execução é medido em milissegundos.
* A taxa de acertos do cache (`hit_percent`) indica a eficiência do cache.
* Queries com alto tempo médio de execução e baixa taxa de acertos podem ser candidatas a otimização.
* O número de chamadas (`calls`) indica a frequência com que a query é executada.
* O desvio padrão do tempo de execução (`stddev_time`) indica a variação no tempo de execução da query.
* A query filtra queries de sistema e queries com menos de 500 chamadas. Esses parâmetros podem ser ajustados para adequar-se as necessidades de cada ambiente.
