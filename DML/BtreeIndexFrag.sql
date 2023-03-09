SELECT i.indexrelid::regclass,
       s.leaf_fragmentation
FROM pg_index AS i
   JOIN pg_class AS t ON i.indexrelid = t.oid
   JOIN pg_opclass AS opc ON i.indclass[0] = opc.oid
   JOIN pg_am ON opc.opcmethod = pg_am.oid
   CROSS JOIN LATERAL pgstatindex(i.indexrelid) AS s
WHERE t.relkind = 'i'
  AND pg_am.amname = 'btree';
