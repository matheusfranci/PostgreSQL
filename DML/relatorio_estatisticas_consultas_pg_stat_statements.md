# Relatório Detalhado de Estatísticas de Consultas do pg_stat_statements no PostgreSQL

## Descrição

Este script SQL gera um relatório abrangente de estatísticas de consultas do `pg_stat_statements` no PostgreSQL. Ele inclui informações sobre tempo de execução, tempo de I/O, número de chamadas, número de linhas, usuário, banco de dados e consulta. O script também normaliza as consultas para agrupar consultas semelhantes e adapta as colunas selecionadas com base na versão do PostgreSQL.

## Query

```sql
\if :postgres_dba_pgvers_13plus
with pg_stat_statements_slice as (
  select *
  from pg_stat_statements
  -- if current database is postgres then generate report for all databases,
  -- otherwise generate for current database only
  where
    current_database() = 'postgres'
    or dbid = (
      select oid
      from pg_database
      where datname = current_database()
    )
), pg_stat_statements_normalized as (
  select
    *,
    translate(
      regexp_replace(
        regexp_replace(
          regexp_replace(
            regexp_replace(
              query,
              e'\\?(::[a-zA-Z_]+)?( *, *\\?(::[a-zA-Z_]+)?)+', '?', 'g'
            ),
            e'\\$[0-9]+(::[a-zA-Z_]+)?( *, *\\$[0-9]+(::[a-zA-Z_]+)?)*', '$N', 'g'
          ),
          e'--.*$', '', 'ng'
        ),
        e'/\\*.*?\\*/', '', 'g'
      ),
      e'\r', ''
    ) as query_normalized
  from pg_stat_statements_slice
), totals as (
  select
    sum(total_exec_time) as total_exec_time,
    sum(blk_read_time+blk_write_time) as io_time,
    sum(total_exec_time-blk_read_time-blk_write_time) as non_io_time,
    sum(calls) as ncalls,
    sum(rows) as total_rows
  from pg_stat_statements_slice
), _pg_stat_statements as (
  select
    (select datname from pg_database where oid = p.dbid) as database,
    (select rolname from pg_roles where oid = p.userid) as username,
    --select shortest query, replace \n\n-- strings to avoid email clients format text as footer
    substring(
      translate(
        replace(
          (array_agg(query order by length(query)))[1],
          e'-- \n',
          e'--\n'
        ),
        e'\r', ''
      ),
      1,
      8192
    ) as query,
    sum(total_exec_time) as total_exec_time,
    sum(blk_read_time) as blk_read_time, sum(blk_write_time) as blk_write_time,
    sum(calls) as calls, sum(rows) as rows
  from pg_stat_statements_normalized p
  group by dbid, userid, md5(query_normalized)
), totals_readable as (
  select
    to_char(interval '1 millisecond' * total_exec_time, 'HH24:MI:SS') as total_exec_time,
    (100*io_time/total_exec_time)::numeric(20,2) as io_time_percent,
    to_char(ncalls, 'FM999,999,999,990') as total_queries,
    (select to_char(count(distinct md5(query)), 'FM999,999,990') from _pg_stat_statements) as unique_queries
  from totals
), statements as (
  select
    (100*total_exec_time/(select total_exec_time from totals)) as time_percent,
    (100*(blk_read_time+blk_write_time)/(select greatest(io_time, 1) from totals)) as io_time_percent,
    (100*(total_exec_time-blk_read_time-blk_write_time)/(select non_io_time from totals)) as non_io_time_percent,
    to_char(interval '1 millisecond' * total_exec_time, 'HH24:MI:SS') as total_exec_time,
    (total_exec_time::numeric/calls)::numeric(20,2) as avg_time,
    ((total_exec_time-blk_read_time-blk_write_time)::numeric/calls)::numeric(20, 2) as avg_non_io_time,
    ((blk_read_time+blk_write_time)::numeric/calls)::numeric(20, 2) as avg_io_time,
    to_char(calls, 'FM999,999,999,990') as calls,
    (100*calls/(select ncalls from totals))::numeric(20, 2) as calls_percent,
    to_char(rows, 'FM999,999,999,990') as rows,
    (100*rows/(select total_rows from totals))::numeric(20, 2) as row_percent,
    database,
    username,
    query
  from _pg_stat_statements
  where
    (total_exec_time-blk_read_time-blk_write_time)/(select non_io_time from totals) >= 0.01
    or (blk_read_time+blk_write_time)/(
      select greatest(io_time, 1) from totals
    ) >= 0.01
    or calls/(select ncalls from totals) >= 0.02
    or rows/(select total_rows from totals) >= 0.02
  union all
  select
    (100*sum(total_exec_time)::numeric/(select total_exec_time from totals)) as time_percent,
    (100*sum(blk_read_time+blk_write_time)::numeric/(select greatest(io_time, 1) from totals)) as io_time_percent,
    (100*sum(total_exec_time-blk_read_time-blk_write_time)::numeric/(select non_io_time from totals)) as non_io_time_percent,
    to_char(interval '1 millisecond' * sum(total_exec_time), 'HH24:MI:SS') as total_exec_time,
    (sum(total_exec_time)::numeric/sum(calls))::numeric(20,2) as avg_time,
    (sum(total_exec_time-blk_read_time-blk_write_time)::numeric/sum(calls))::numeric(20, 2) as avg_non_io_time,
    (sum(blk_read_time+blk_write_time)::numeric/sum(calls))::numeric(20, 2) as avg_io_time,
    to_char(sum(calls), 'FM999,999,999,990') as calls,
    (100*sum(calls)/(select ncalls from totals))::numeric(20, 2) as calls_percent,
    to_char(sum(rows), 'FM999,999,999,990') as rows,
    (100*sum(rows)/(select total_rows from totals))::numeric(20, 2) as row_percent,
    'all' as database,
    'all' as username,
    'other' as query
  from _pg_stat_statements
  where
    not (
      (total_exec_time-blk_read_time-blk_write_time)/(select non_io_time from totals) >= 0.01
      or (blk_read_time+blk_write_time)/(select greatest(io_time, 1) from totals) >= 0.01
      or calls/(select ncalls from totals)>=0.02 or rows/(select total_rows from totals) >= 0.02
    )
), statements_readable as (
  select row_number() over (order by s.time_percent desc) as pos,
    to_char(time_percent, 'FM990.0') || '%' as time_percent,
    to_char(io_time_percent, 'FM990.0') || '%' as io_time_percent,
    to_char(non_io_time_percent, 'FM990.0') || '%' as non_io_time_percent,
    to_char(avg_io_time*100/(coalesce(nullif(avg_time, 0), 1)), 'FM990.0') || '%' as avg_io_time_percent,
    total_exec_time, avg_time, avg_non_io_time, avg_io_time, calls, calls_percent, rows, row_percent,
    database, username, query
  from statements s
  where calls is not null
)
select
  e'total time:\t' || total_exec_time || ' (IO: ' || io_time_percent || E'%)\n'
  || e'total queries:\t' || total_queries || ' (unique: ' || unique_queries || E')\n'
  || 'report for ' || (select case when current_database() = 'postgres' then 'all databases' else current_database() || ' database' end)
  || E', version b0.9.6'
  || ' @ PostgreSQL '
  || (select setting from pg_settings where name='server_version') || E'\ntracking '
  || (select setting from pg_settings where name='pg_stat_statements.track') || ' '
  || (select setting from pg_settings where name='pg_stat_statements.max') || ' queries, utilities '
  || (select setting from pg_settings where name='pg_stat_statements.track_utility')
  || ', logging ' || (select (case when setting = '0' then 'all' when setting = '-1' then 'none' when setting::int > 1000 then (setting::numeric/1000)::numeric(20, 1) || 's+' else setting || 'ms+' end) from pg_settings where name='log_min_duration_statement')
  || E' queries\n'
  || (
    select coalesce(string_agg('WARNING: database ' || datname || ' must be vacuumed within ' || to_char(2147483647 - age(datfrozenxid), 'FM999,999,999,990') || ' transactions', E'\n' order by age(datfrozenxid) desc) || E'\n', '')
    from pg_database where (2147483647 - age(datfrozenxid)) < 200000000
  ) || E'\n'
from totals_readable
union all
(
select
  e'=============================================================================================================\n'
  || 'pos:' || pos || E'\t total time: ' || total_exec_time || ' (' || time_percent
  || ', IO: ' || io_time_percent || ', Non-IO: ' || non_io_time_percent || E')\t calls: '
  || calls || ' (' || calls_percent || E'%)\t avg_time: ' || avg_time
  || 'ms (IO: ' || avg_io_time_percent || E')\n' || 'user: '
  || username || E'\t db: ' || database || E'\t rows: ' || rows
  || ' (' || row_percent || '%)' || E'\t query:\n' || query || E'\n'
from statements_readable
order by pos
);

\else
with pg_stat_statements_slice as (
  select *
  from pg_stat_statements
  -- if current database is postgres then generate report for all databases,
  -- otherwise generate for current database only
  where
    current_database() = 'postgres'
    or dbid = (
      select oid
      from pg_database
      where datname = current_database()
    )
), pg_stat_statements_normalized as (
  select
    *,
    translate(
      regexp_replace(
        regexp_replace(
          regexp_replace(
            regexp_replace(
              query,
              e'\\?(::[a-zA-Z_]+)?( *, *\\?(::[a-zA-Z_]+)?)+', '?', 'g'
            ),
            e'\\$[0-9]+(::[a-zA-Z_]+)?( *, *\\$[0-9]+(::[a-zA-Z_]+)?)*', '$N', 'g'
          ),
          e'--.*$', '', 'ng'
        ),
        e'/\\*.*?\\*/', '', 'g'
      ),
      e'\r', ''
    ) as query_normalized
  from pg_stat_statements_slice
), totals as (
  select
    sum(total_time) as total_time,
    sum(blk_read_time+blk_write_time) as io_time,
    sum(total_time-blk_read_time-blk_write_time) as non_io_time,
    sum(calls) as ncalls,
    sum(rows) as total_rows
  from pg_stat_statements_slice
), _pg_stat_statements as (
  select
    (select datname from pg_database where oid = p.dbid) as database,
    (select rolname from pg_roles where oid = p.userid) as username,
    --select shortest query, replace \n\n-- strings to avoid email clients format text as footer
    substring(
      translate(
        replace(
          (array_agg(query order by length(query)))[1],
          e'-- \n',
          e'--\n'
        ),
        e'\r', ''
      ),
      1,
      8192
    ) as query,
    sum(total_time) as total_time,
    sum(blk_read_time) as blk_read_time, sum(blk_write_time) as blk_write_time,
    sum(calls) as calls, sum(rows) as rows
  from pg_stat_statements_normalized p
  group by dbid, userid, md5(query_normalized)
), totals_readable as (
  select
    to_char(interval '1 millisecond' * total_time, 'HH24:MI:SS') as total_time,
    (100*io_time/total_time)::numeric(20,2) as io_time_percent,
    to_char(ncalls, 'FM999,999,999,990') as total_queries,
    (select to_char(count(distinct md5(query)), 'FM999,999,990') from _pg_stat_statements) as unique_queries
  from totals
), statements as (
  select
    (100*total_time/(select total_time from totals)) as time_percent,
    (100*(blk_read_time+blk_write_time)/(select greatest(io_time, 1) from totals)) as io_time_percent,
    (100*(total_time-blk_read_time-blk_write_time)/(select non_io_time from totals)) as non_io_time_percent,
    to_char(interval '1 millisecond' * total_time, 'HH24:MI:SS') as total_time,
    (total_time::numeric/calls)::numeric(20,2) as avg_time,
    ((total_time-blk_read_time-blk_write_time)::numeric/calls)::numeric(20, 2) as avg_non_io_time,
    ((blk_read_time+blk_write_time)::numeric/calls)::numeric(20, 2) as avg_io_time,
    to_char(calls, 'FM999,999,999,990') as calls,
    (100*calls/(select ncalls from totals))::numeric(20, 2) as calls_percent,
    to_char(rows, 'FM999,999,999,990') as rows,
    (100*rows/(select total_rows from totals))::numeric(20, 2) as row_percent,
    database,
    username,
    query
  from _pg_stat_statements
  where
    (total_time-blk_read_time-blk_write_time)/(select non_io_time from totals) >= 0.01
    or (blk_read_time+blk_write_time)/(
      select greatest(io_time, 1) from totals
    ) >= 0.01
    or calls/(select ncalls from totals) >= 0.02
    or rows/(select total_rows from totals) >= 0.02
  union all
  select
    (100*sum(total_time)::numeric/(select total_time from totals)) as time_percent,
    (100*sum(blk_read_time+blk_write_time)::numeric/(select greatest(io_time, 1) from totals)) as io_time_percent,
    (100*sum(total_time-blk_read_time-blk_write_time)::numeric/(select non_io_time from totals)) as non_io_time_percent,
    to_char(interval '1 millisecond' * sum(total_time), 'HH24:MI:SS') as total_time,
    (sum(total_time)::numeric/sum(calls))::numeric(20,2) as avg_time,
    (sum(total_time-blk_read_time-blk_write_time)::numeric/sum(calls))::numeric(20, 2) as avg_non_io_time,
    (sum(blk_read_time+blk_write_time)::numeric/sum(calls))::numeric(20, 2) as avg_io_time,
    to_char(sum(calls), 'FM999,999,999,990') as calls,
    (100*sum(calls)/(select ncalls from totals))::numeric(20, 2) as calls_percent,
    to_char(sum(rows), 'FM999,999,999,990') as rows,
    (100*sum(rows)/(select total_rows from totals))::numeric(20, 2) as row_percent,
    'all' as database,
    'all' as username,
    'other' as query
  from _pg_stat_statements
  where
    not (
      (total_time-blk_read_time-blk_write_time)/(select non_io_time from totals) >= 0.01
      or (blk_read_time+blk_write_time)/(select greatest(io_time, 1) from totals) >= 0.01
      or calls/(select ncalls from totals)>=0.02 or rows/(select total_rows from totals) >= 0.02
    )
), statements_readable as (
  select row_number() over (order by s.time_percent desc) as pos,
    to_char(time_percent, 'FM990.0') || '%' as time_percent,
    to_char(io_time_percent, 'FM990.0') || '%' as io_time_percent,
    to_char(non_io_time_percent, 'FM990.0') || '%' as non_io_time_percent,
    to_char(avg_io_time*100/(coalesce(nullif(avg_time, 0), 1)), 'FM990.0') || '%' as avg_io_time_percent,
    total_time, avg_time, avg_non_io_time, avg_io_time, calls, calls_percent, rows, row_percent,
    database, username, query
  from statements s
  where calls is not null
)
select
  e'total time:\t' || total_time || ' (IO: ' || io_time_percent || E'%)\n'
  || e'total queries:\t' || total_queries || ' (unique: ' || unique_queries || E')\n'
  || 'report for ' || (select case when current_database() = 'postgres' then 'all databases' else current_database() || ' database' end)
  || E', version b0.9.6'
  || ' @ PostgreSQL '
  || (select setting from pg_settings where name='server_version') || E'\ntracking '
  || (select setting from pg_settings where name='pg_stat_statements.track') || ' '
  || (select setting from pg_settings where name='pg_stat_statements.max') || ' queries, utilities '
  || (select setting from pg_settings where name='pg_stat_statements.track_utility')
  || ', logging ' || (select (case when setting = '0' then 'all' when setting = '-1' then 'none' when setting::int > 1000 then (setting::numeric/1000)::numeric(20, 1) || 's+' else setting || 'ms+' end) from pg_settings where name='log_min_duration_statement')
  || E' queries\n'
  || (
    select coalesce(string_agg('WARNING: database ' || datname || ' must be vacuumed within ' || to_char(2147483647 - age(datfrozenxid), 'FM999,999,999,990') || ' transactions', E'\n' order by age(datfrozenxid) desc) || E'\n', '')
    from pg_database where (2147483647 - age(datfrozenxid)) < 200000000
  ) || E'\n'
from totals_readable
union all
(
select
  e'=============================================================================================================\n'
  || 'pos:' || pos || E'\t total time: ' || total_time || ' (' || time_percent
  || ', IO: ' || io_time_percent || ', Non-IO: ' || non_io_time_percent || E')\t calls: '
  || calls || ' (' || calls_percent || E'%)\t avg_time: ' || avg_time
  || 'ms (IO: ' || avg_io_time_percent || E')\n' || 'user: '
  || username || E'\t db: ' || database || E'\t rows: ' || rows
  || ' (' || row_percent || '%)' || E'\t query:\n' || query || E'\n'
from statements_readable
order by pos
);
\endif
```

## Explicação Detalhada

O script é dividido em várias CTEs (Common Table Expressions) para organizar e processar os dados:

1.  **`pg_stat_statements_slice`**:
    * Seleciona dados da visão `pg_stat_statements`.
    * Filtra os resultados para incluir apenas o banco de dados atual ou todos os bancos de dados se o banco de dados atual for `postgres`.

2.  **`pg_stat_statements_normalized`**:
    * Normaliza as consultas para agrupar consultas semelhantes, substituindo literais e variáveis por placeholders (`?` e `$N`).
    * Remove comentários e quebras de linha.

3.  **`totals`**:
    * Calcula os totais de tempo de execução, tempo de I/O, número de chamadas e número de linhas.

4.  **`_pg_stat_statements`**:
    * Agrupa as consultas normalizadas por banco de dados, usuário e hash da consulta normalizada.
    * Seleciona a consulta mais curta para cada grupo.
    * Calcula a soma do tempo de execução, tempo de I/O, número de chamadas e número de linhas para cada grupo.

5.  **`totals_readable`**:
    * Formata os totais para leitura humana.

6.  **`statements`**:
    * Calcula as porcentagens de tempo de execução, tempo de I/O, número de chamadas e número de linhas para cada consulta.
    * Calcula o tempo médio de execução e o tempo médio de I/O por chamada.
    * Filtra as consultas para incluir apenas aquelas que representam uma porcentagem significativa do tempo total, chamadas ou linhas.
    * Adiciona uma linha de resumo para as consultas restantes.

7.  **`statements_readable`**:
    * Formata as estatísticas das consultas para leitura humana.

8.  **Consulta Principal**:
    * Gera um relatório que inclui os totais formatados, as estatísticas das consultas formatadas e informações sobre a configuração do `pg_stat_statements`.
    * Inclui um aviso se algum banco de dados precisar de `VACUUM`.

## Considerações

* O script adapta as colunas selecionadas com base na versão do PostgreSQL, usando `total_exec_time` e `total_plan_time` para PostgreSQL 13+ e `total_time` para versões anteriores.
* A normalização das consultas ajuda a agrupar consultas semelhantes, mesmo que tenham literais ou variáveis diferentes.
* O relatório inclui porcentagens e tempos médios para facilitar a identificação de consultas problemáticas.
* O aviso de `VACUUM` ajuda a garantir que as estatísticas sejam precisas.
* O script é projetado para ser executado como um script SQL autônomo.
* O resultado é formatado para ser lido em um terminal ou enviado por e-mail.
* O script é muito útil para monitorar e otimizar o desempenho de consultas no PostgreSQL.
