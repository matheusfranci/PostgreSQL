# Atividades em Andamento no Banco de Dados rideshare_development

## Descrição

Este script SQL recupera informações sobre as atividades em andamento no banco de dados `rideshare_development`. Ele fornece o ID do processo (PID), o tipo de evento de espera, o evento de espera, os primeiros 60 caracteres da consulta, a hora de início do backend, a hora de início da consulta e o tempo decorrido desde o início da consulta.

## Query

```sql
SELECT
    pid,
    wait_event_type,
    wait_event,
    LEFT(query, 60) AS query,
    backend_start,
    query_start,
    (CURRENT_TIMESTAMP - query_start) AS ago
FROM pg_stat_activity
WHERE datname = 'rideshare_development';
```

## Explicação Detalhada

* **`pg_stat_activity`**: Esta visão do sistema contém informações sobre as atividades em andamento no banco de dados.
* **`pid`**: O ID do processo (PID) da atividade.
* **`wait_event_type`**: O tipo de evento de espera, se a atividade estiver esperando por algo.
* **`wait_event`**: O evento de espera específico, se a atividade estiver esperando por algo.
* **`LEFT(query, 60) AS query`**: Os primeiros 60 caracteres da consulta SQL em execução.
* **`backend_start`**: A hora em que o backend foi iniciado.
* **`query_start`**: A hora em que a consulta foi iniciada.
* **`(CURRENT_TIMESTAMP - query_start) AS ago`**: O tempo decorrido desde o início da consulta.
* **`WHERE datname = 'rideshare_development'`**: Filtra os resultados para incluir apenas atividades no banco de dados `rideshare_development`.

## Exemplos de Uso

Este script pode ser usado para:

* Monitorar as atividades em andamento no banco de dados `rideshare_development`.
* Identificar consultas de longa duração.
* Identificar atividades que estão esperando por recursos.
* Diagnosticar problemas de desempenho.

## Considerações

* A coluna `wait_event_type` e `wait_event` são nulas se a atividade não estiver esperando por nada.
* A coluna `query` pode ser truncada se a consulta for maior que 60 caracteres.
* O tempo decorrido (`ago`) é calculado usando a hora atual do sistema.
* Essa query é útil para monitorar o que está acontecendo no banco de dados especificado.
