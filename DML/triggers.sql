SELECT n.nspname AS schema,
       c.relname AS table,
       t.tgname  AS trigger, 
       p.proname AS function_called,
       CASE WHEN t.tgconstrrelid > 0
            THEN (SELECT relname 
                   FROM pg_class 
                  WHERE oid = t.tgconstrrelid)
            ELSE ''
        END      AS constr_tbl,
       t.tgenabled AS mode,
       t.tgconstrindid
  FROM pg_trigger t
  INNER JOIN pg_proc p  ON ( p.oid = t.tgfoid)
  INNER JOIN pg_class c ON (c.oid = t.tgrelid)
  INNER JOIN pg_namespace n ON (n.oid = c.relnamespace)
  WHERE tgname NOT LIKE 'pg_%' 
    AND tgname NOT LIKE 'RI_%'  -- < comment out to see triggers
 ORDER BY 1, 2;
