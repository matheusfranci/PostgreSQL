SELECT t.schemaname,
    t.relname,
    l.locktype,
    l.page,
    l.virtualtransaction,
    l.pid,
    l.mode,
    l.granted
   FROM pg_locks l
   JOIN pg_stat_all_tables t ON l.relation = t.relid
  WHERE t.schemaname <> 'pg_toast'::name AND t.schemaname <> 'pg_catalog'::name
  ORDER BY t.schemaname, t.relname;

SELECT pg_cancel_backend('%pid%');
