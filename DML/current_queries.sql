SELECT backend_start as be_start,
       datname,
       pid as pid,
       client_addr,
       usename as user,
       state,
       query,
       wait_event_type,          --< COMMENT OUT FOR 9.4 and below
/*                               --< UNCOMMENT FOR 9.4 and below
       CASE WHEN waiting = TRUE  
            THEN 'BLOCKED'
            ELSE 'no'
        END as waiting,
*/        
       query_start,
       current_timestamp - query_start as duration 
  FROM pg_stat_activity
 WHERE pg_backend_pid() <> pid
ORDER BY 1, 
         datname,
         query_start;

--SELECT * FROM pg_stat_activity LIMIT 2;