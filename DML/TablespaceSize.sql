SELECT
    pg_size_pretty (
        pg_tablespace_size ('pg_default')
    );
