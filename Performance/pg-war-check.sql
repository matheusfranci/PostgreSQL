-- 1) CONEXOES
SELECT now() as horario,
       count(*) as total_conexoes,
       (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') as max_connections,
       round(
           100.0 * count(*) /
           (SELECT setting::int FROM pg_settings WHERE name = 'max_connections'),
       2) as percentual_uso
FROM pg_stat_activity;

-- 2) SESSOES POR ESTADO
SELECT state, count(*)
FROM pg_stat_activity
GROUP BY state
ORDER BY count(*) DESC;

-- 3) QUERIES EM EXECUCAO
SELECT pid,
       now() - query_start AS tempo_execucao,
       state,
       wait_event_type,
       wait_event,
       left(query,120) as query
FROM pg_stat_activity
WHERE state <> 'idle'
ORDER BY tempo_execucao DESC
LIMIT 10;

-- 4) LOCKS NAO CONCEDIDOS
SELECT pid, locktype, relation::regclass, mode
FROM pg_locks
WHERE NOT granted;

-- 5) TRANSACOES ABERTAS
SELECT pid,
       now() - xact_start AS tempo_transacao,
       state,
       left(query,120)
FROM pg_stat_activity
WHERE xact_start IS NOT NULL
ORDER BY tempo_transacao DESC
LIMIT 10;

-- 6) EVENTOS DE ESPERA
SELECT wait_event_type,
       wait_event,
       count(*)
FROM pg_stat_activity
WHERE wait_event IS NOT NULL
GROUP BY 1,2
ORDER BY count(*) DESC;

-- 7) HIT RATIO
SELECT datname,
       blks_read,
       blks_hit,
       round(100.0 * blks_hit / nullif(blks_hit + blks_read,0), 2) AS hit_ratio
FROM pg_stat_database
WHERE datname = current_database();

-- 8) ULTIMO AUTOVACUUM
SELECT relname,
       last_autovacuum,
       last_autoanalyze
FROM pg_stat_user_tables
ORDER BY last_autovacuum NULLS FIRST
LIMIT 10;

-- 9) TOP QUERIES (SE EXISTIR EXTENSAO)
SELECT query,
       calls,
       total_exec_time,
       mean_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 5;

-- 10 % de sessões esperando cliente
WITH total AS (
    SELECT count(*) AS total_sessoes
    FROM pg_stat_activity
),
client_wait AS (
    SELECT count(*) AS total_client_wait
    FROM pg_stat_activity
    WHERE wait_event_type = 'Client'
)
SELECT 
    t.total_sessoes,
    c.total_client_wait,
    round(100.0 * c.total_client_wait / nullif(t.total_sessoes,0),2) 
        AS percentual_esperando_cliente
FROM total t, client_wait c;

-- 11 Detectar possível gargalo externo (rede/aplicação)
WITH waits AS (
    SELECT wait_event_type,
           wait_event,
           count(*) AS total
    FROM pg_stat_activity
    WHERE state = 'active'
      AND wait_event IS NOT NULL
    GROUP BY 1,2
),
total_active AS (
    SELECT count(*) AS total
    FROM pg_stat_activity
    WHERE state = 'active'
)
SELECT 
    w.wait_event_type,
    w.wait_event,
    w.total,
    round(100.0 * w.total / nullif(t.total,0),2) AS percentual_das_ativas
FROM waits w
CROSS JOIN total_active t
ORDER BY percentual_das_ativas DESC;
