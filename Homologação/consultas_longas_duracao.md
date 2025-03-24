# Consultas de Longa Duração no PostgreSQL

## Descrição

Este script SQL recupera informações sobre consultas em execução no PostgreSQL que estão rodando por mais de 5 minutos. Ele fornece o ID do processo (PID), a duração da consulta, o texto da consulta e o estado da conexão.

## Query

```sql
SELECT
    pid,
    NOW() - pg_stat_activity.query_start AS duration,
    query,
    state
FROM pg_stat_activity
WHERE (NOW() - pg_stat_activity.query_start) > INTERVAL '5 minutes';
```

## Explicação Detalhada

* **`pg_stat_activity`**: Esta tabela do sistema contém informações sobre a atividade atual de cada processo de servidor.
* **`pid`**: O ID do processo (PID) da conexão.
* **`NOW() - pg_stat_activity.query_start AS duration`**: Calcula a duração da consulta subtraindo o tempo de início da consulta (`query_start`) do tempo atual (`NOW()`) e renomeia a coluna resultante para `duration`.
* **`query`**: O texto da consulta em execução.
* **`state`**: O estado atual da conexão (por exemplo, `active`, `idle`).
* **`WHERE (NOW() - pg_stat_activity.query_start) > INTERVAL '5 minutes'`**: Filtra os resultados para incluir apenas as consultas que estão rodando por mais de 5 minutos.

## Exemplos de Uso

Este script pode ser usado para:

* Identificar consultas de longa duração que podem estar causando problemas de desempenho.
* Monitorar consultas em execução em tempo real.
* Diagnosticar problemas de bloqueio ou deadlock.
* Identificar queries que necessitam de otimização.

## Considerações

* A duração da consulta é calculada usando a diferença entre o tempo atual e o tempo de início da consulta.
* O intervalo de tempo (5 minutos) pode ser ajustado conforme a necessidade.
* A coluna `state` fornece informações sobre o estado atual da conexão, que pode ser útil para diagnosticar problemas.
* A coluna `query` mostra o texto da consulta em execução, o que pode ajudar a identificar a causa da longa duração.
* É importante ter cautela ao finalizar processos de longa duração, pois isso pode interromper transações importantes.
* Este script é uma ferramenta útil para monitorar e diagnosticar problemas de desempenho relacionados a consultas de longa duração.
* A query não considera o tempo de bloqueios, apenas o tempo de execução da query.
