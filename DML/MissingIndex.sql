Solution:
This will actually work equally well on SQL Server, MySQL and any other database that supports the Information_Schema standard. It won't check for unique indexes though.


SELECT c.table_schema, c.table_name, c.table_type
FROM information_schema.tables c
WHERE c.table_type = 'BASE TABLE' AND c.table_schema NOT IN('information_schema', 'pg_catalog') 
AND
NOT EXISTS (SELECT cu.table_name 
				FROM information_schema.key_column_usage cu
				WHERE cu.table_schema = c.table_schema AND
					cu.table_name = c.table_name)
ORDER BY c.table_schema, c.table_name;

Problem: Return all non-system tables that are missing primary keys and have no unique indexes

Solution - this one is not quite as portable. We had to delve into the pg_catalog since we couldn't find a table in information schema that would tell us anything about any indexes but primary keys and foreign keys. Even though in theory primary keys and unique indexes are the same, they are not from a meta data standpoint.


SELECT c.table_schema, c.table_name, c.table_type
FROM information_schema.tables c
WHERE  c.table_schema NOT IN('information_schema', 'pg_catalog') AND c.table_type = 'BASE TABLE' 
AND NOT EXISTS(SELECT i.tablename  
				FROM pg_catalog.pg_indexes i 
			WHERE i.schemaname = c.table_schema 
				AND i.tablename = c.table_name AND indexdef LIKE '%UNIQUE%')
AND
NOT EXISTS (SELECT cu.table_name 
				FROM information_schema.key_column_usage cu
				WHERE cu.table_schema = c.table_schema AND
					cu.table_name = c.table_name)
ORDER BY c.table_schema, c.table_name;

Problem - List all tables with geometry fields that have no index on the geometry field.

Solution -

SELECT c.table_schema, c.table_name, c.column_name
FROM (SELECT * FROM 
	information_schema.tables WHERE table_type = 'BASE TABLE') As t  INNER JOIN
	(SELECT * FROM information_schema.columns WHERE udt_name = 'geometry') c  
		ON (t.table_name = c.table_name AND t.table_schema = c.table_schema)
		LEFT JOIN pg_catalog.pg_indexes i ON 
			(i.tablename = c.table_name AND i.schemaname = c.table_schema 
				AND  indexdef LIKE '%' || c.column_name || '%') 
WHERE i.tablename IS NULL
ORDER BY c.table_schema, c.table_name;
