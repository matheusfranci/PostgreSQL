# Identificar Queries de Longa Duração no PostgreSQL

## Descrição

Esta query lista informações sobre queries em execução no PostgreSQL que estão em execução por mais de 5 minutos. Ela fornece detalhes como o PID do processo, o usuário que executou a query, o tempo de início da query, o tempo de execução, o texto da query, o estado do processo e informações sobre eventos de espera.

## Query

```sql
SELECT
    pid,
    user,
    pg_stat_activity.query_start,
    now() - pg_stat_activity.query_start AS query_time,
    query,
    state,
    wait_event_type,
    wait_event
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';
```

## Explicação Detalhada

* `pg_stat_activity`: Esta visão do sistema fornece informações sobre as atividades em execução no servidor PostgreSQL.
* `pid`: O ID do processo (PID) que está executando a query.
* `user`: O nome do usuário que executou a query.
* `pg_stat_activity.query_start`: O tempo em que a query começou a ser executada.
* `now() - pg_stat_activity.query_start AS query_time`: O tempo de execução da query (intervalo de tempo).
* `query`: O texto da query em execução.
* `state`: O estado atual do processo (por exemplo, `active`, `idle`, `idle in transaction`).
* `wait_event_type`: O tipo de evento de espera (se o processo estiver esperando).
* `wait_event`: O evento de espera específico (se o processo estiver esperando).
* `WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes'`: Filtra os resultados para incluir apenas queries que estão em execução por mais de 5 minutos.

## Exemplos de Uso

Esta query pode ser usada para:

* Identificar queries lentas que estão afetando o desempenho do banco de dados.
* Monitorar queries de longa duração em ambientes de produção.
* Diagnosticar problemas de desempenho e bloqueios.
* Auxiliar na otimização de queries.

## Considerações

* Queries de longa duração podem indicar problemas de desempenho ou bloqueios.
* É importante analisar o texto da query e o estado do processo para entender a causa da lentidão.
* O tempo de execução da query (`query_time`) é um intervalo de tempo, que pode ser formatado de diferentes maneiras.
* As colunas `wait_event_type` e `wait_event` fornecem informações sobre eventos de espera, que podem ajudar a identificar bloqueios ou outros problemas de desempenho.
* O tempo de 5 minutos pode ser ajustado para atender às necessidades do seu ambiente.
* O estado da query pode ser `active`, `idle`, `idle in transaction`, entre outros.
