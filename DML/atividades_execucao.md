# Listar Atividades em Execução no PostgreSQL

## Descrição

Esta query lista informações detalhadas sobre as atividades em execução no PostgreSQL, excluindo o processo atual. Ela exibe o tempo de início do backend, o nome do banco de dados, o PID do processo, o endereço do cliente, o nome do usuário, o estado do processo, a query em execução, o tipo de evento de espera (se aplicável), o tempo de início da query e a duração da query.

## Query

```sql
SELECT backend_start AS be_start,
       datname,
       pid AS pid,
       client_addr,
       usename AS user,
       state,
       query,
       wait_event_type,  --< COMMENT OUT FOR 9.4 and below
       /* --< UNCOMMENT FOR 9.4 and below
       CASE WHEN waiting = TRUE
            THEN 'BLOCKED'
            ELSE 'no'
       END AS waiting,
       */
       query_start,
       current_timestamp - query_start AS duration
FROM pg_stat_activity
WHERE pg_backend_pid() <> pid
ORDER BY 1, datname, query_start;
```

## Explicação Detalhada

* `pg_stat_activity`: Esta visão do sistema fornece informações sobre as atividades em execução no servidor PostgreSQL.
* `backend_start AS be_start`: O tempo em que o processo de backend foi iniciado.
* `datname`: O nome do banco de dados em que a atividade está em execução.
* `pid AS pid`: O ID do processo (PID) da atividade.
* `client_addr`: O endereço IP do cliente que iniciou a atividade.
* `usename AS user`: O nome do usuário que iniciou a atividade.
* `state`: O estado atual do processo (por exemplo, `active`, `idle`, `idle in transaction`).
* `query`: O texto da query em execução.
* `wait_event_type`: O tipo de evento de espera (se o processo estiver esperando).
* `query_start`: O tempo em que a query começou a ser executada.
* `current_timestamp - query_start AS duration`: A duração da query (intervalo de tempo).
* `WHERE pg_backend_pid() <> pid`: Filtra os resultados para excluir o processo atual.
* `ORDER BY 1, datname, query_start`: Ordena os resultados pelo tempo de início do backend, nome do banco de dados e tempo de início da query.
* A parte comentada para versões abaixo da 9.4, mostra o estado de bloqueio.

## Exemplos de Uso

Esta query pode ser usada para:

* Monitorar as atividades em execução no banco de dados.
* Identificar queries lentas ou problemáticas.
* Diagnosticar problemas de desempenho e bloqueios.
* Verificar o estado das conexões de clientes.

## Considerações

* A coluna `state` indica o estado atual do processo, que pode ser útil para identificar processos ociosos ou em execução prolongada.
* A coluna `duration` fornece a duração da query, que pode ajudar a identificar queries lentas.
* As colunas `wait_event_type` fornecem informações sobre eventos de espera, que podem ajudar a identificar bloqueios ou outros problemas de desempenho.
* A query exclui o processo atual para evitar a exibição de seus próprios dados.
* A ordenação facilita a análise das atividades em execução.
* A parte comentada é para versões do postgres abaixo da 9.4, onde a coluna `waiting` era utilizada ao invés de `wait_event_type`.
