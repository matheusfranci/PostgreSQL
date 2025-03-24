# Status e Informações do Banco de Dados PostgreSQL

## Descrição

Este script SQL fornece uma visão geral abrangente do estado e desempenho do banco de dados PostgreSQL. Ele inclui informações sobre a versão do PostgreSQL, configurações, status de replicação (se aplicável), tempo de atividade, estatísticas de checkpoint, uso de cache, conflitos, arquivos temporários e deadlocks.

## Query

```sql
/*
Para versões do Postgres anteriores a 10, execute isto primeiro:

  \set postgres_dba_last_wal_receive_lsn pg_last_xlog_receive_location
  \set postgres_dba_last_wal_replay_lsn pg_last_xlog_replay_location
  \set postgres_dba_is_wal_replay_paused pg_is_xlog_replay_paused
*/

WITH data AS (
    SELECT s.*
    FROM pg_stat_database s
    WHERE s.datname = current_database()
)
SELECT 'Postgres Version' AS metric, version() AS value
UNION ALL
SELECT 'Config file' AS metric, (SELECT setting FROM pg_settings WHERE name = 'config_file') AS value
UNION ALL
SELECT 'Role' AS metric,
    CASE
        WHEN pg_is_in_recovery() THEN 'Replica' || ' (delay: '
            || ((((CASE
                        WHEN :postgres_dba_last_wal_receive_lsn() = :postgres_dba_last_wal_replay_lsn() THEN 0
                        ELSE EXTRACT(epoch FROM now() - pg_last_xact_replay_timestamp())
                    END)::INT)::TEXT || ' second')::INTERVAL)::TEXT
            || '; paused: ' || :postgres_dba_is_wal_replay_paused()::TEXT || ')'
        ELSE 'Master'
    END AS value
UNION ALL
(
    WITH repl_groups AS (
        SELECT sync_state, state, string_agg(host(client_addr), ', ') AS hosts
        FROM pg_stat_replication
        GROUP BY 1, 2
    )
    SELECT 'Replicas', string_agg(sync_state || '/' || state || ': ' || hosts, E'\n')
    FROM repl_groups
)
UNION ALL
SELECT 'Started At', pg_postmaster_start_time()::TIMESTAMPTZ(0)::TEXT
UNION ALL
SELECT 'Uptime', (now() - pg_postmaster_start_time())::INTERVAL(0)::TEXT
UNION ALL
SELECT 'Checkpoints', (SELECT (checkpoints_timed + checkpoints_req)::TEXT FROM pg_stat_bgwriter)
UNION ALL
SELECT 'Forced Checkpoints', (SELECT ROUND(100.0 * checkpoints_req::NUMERIC / (NULLIF(checkpoints_timed + checkpoints_req, 0)), 1)::TEXT || '%' FROM pg_stat_bgwriter)
UNION ALL
SELECT 'Checkpoint MB/sec', (SELECT ROUND((NULLIF(buffers_checkpoint::NUMERIC, 0) / ((1024.0 * 1024 / (current_setting('block_size')::NUMERIC)) * EXTRACT('epoch' FROM now() - stats_reset)))::NUMERIC, 6)::TEXT FROM pg_stat_bgwriter)
UNION ALL
SELECT REPEAT('-', 33), REPEAT('-', 88)
UNION ALL
SELECT 'Database Name' AS metric, datname AS value FROM data
UNION ALL
SELECT 'Database Size', pg_size_pretty(pg_database_size(current_database()))
UNION ALL
SELECT 'Stats Since', stats_reset::TIMESTAMPTZ(0)::TEXT FROM data
UNION ALL
SELECT 'Stats Age', (now() - stats_reset)::INTERVAL(0)::TEXT FROM data
UNION ALL
SELECT 'Installed Extensions', (WITH exts AS (SELECT extname || ' ' || extversion e, (-1 + ROW_NUMBER() OVER (ORDER BY extname)) / 5 i FROM pg_extension), lines(l) AS (SELECT string_agg(e, ', ' ORDER BY i) l FROM exts GROUP BY i) SELECT string_agg(l, E'\n') FROM lines)
UNION ALL
SELECT 'Cache Effectiveness', (ROUND(blks_hit * 100::NUMERIC / (blks_hit + blks_read), 2))::TEXT || '%' FROM data
UNION ALL
SELECT 'Successful Commits', (ROUND(xact_commit * 100::NUMERIC / (xact_commit + xact_rollback), 2))::TEXT || '%' FROM data
UNION ALL
SELECT 'Conflicts', conflicts::TEXT FROM data
UNION ALL
SELECT 'Temp Files: total size', pg_size_pretty(temp_bytes)::TEXT FROM data
UNION ALL
SELECT 'Temp Files: total number of files', temp_files::TEXT FROM data
UNION ALL
SELECT 'Temp Files: avg file size', pg_size_pretty(temp_bytes::NUMERIC / NULLIF(temp_files, 0))::TEXT FROM data
UNION ALL
SELECT 'Deadlocks', deadlocks::TEXT FROM data;
```

## Explicação Detalhada

* **Versão do PostgreSQL e arquivo de configuração:**
    * Exibe a versão do PostgreSQL e o caminho do arquivo de configuração.
* **Função do nó (Master/Replica):**
    * Indica se o nó é um mestre ou réplica, e se for réplica, mostra o atraso e o estado de pausa.
* **Informações de réplicas:**
    * Lista as réplicas conectadas, seus estados e atrasos.
* **Tempo de atividade:**
    * Exibe o tempo desde que o servidor foi iniciado.
* **Estatísticas de checkpoint:**
    * Mostra o número de checkpoints, a porcentagem de checkpoints forçados e a taxa de MB/segundo de checkpoints.
* **Informações do banco de dados:**
    * Exibe o nome do banco de dados, tamanho, tempo desde a última coleta de estatísticas e idade das estatísticas.
* **Extensões instaladas:**
    * Lista as extensões instaladas no banco de dados.
* **Eficácia do cache:**
    * Calcula a porcentagem de acertos no cache.
* **Taxa de commits bem-sucedidos:**
    * Calcula a porcentagem de commits bem-sucedidos.
* **Conflitos:**
    * Exibe o número de conflitos.
* **Arquivos temporários:**
    * Mostra o tamanho total, número total e tamanho médio dos arquivos temporários.
* **Deadlocks:**
    * Exibe o número de deadlocks.

## Exemplos de Uso

Esta query pode ser usada para:

* Obter uma visão geral rápida do estado do banco de dados.
* Monitorar o desempenho e identificar possíveis problemas.
* Verificar o status da replicação.
* Acompanhar o uso de recursos do banco de dados.

## Considerações

* As variáveis `:postgres_dba_last_wal_receive_lsn`, `:postgres_dba_last_wal_replay_lsn` e `:postgres_dba_is_wal_replay_paused` precisam ser definidas corretamente para que as informações de replicação sejam exibidas corretamente. Para versões anteriores ao postgres 10, é necessário executar os comandos informados no inicio do script.
* A taxa de MB/segundo de checkpoints pode variar dependendo da carga do sistema.
* As informações sobre arquivos temporários podem ajudar a identificar consultas que estão usando muito espaço em disco.
* A taxa de acertos no cache indica a eficiência do cache de buffer do banco de dados.
* O numero de deadlocks indica a quantidade de transações que foram canceladas pelo banco de dados.
