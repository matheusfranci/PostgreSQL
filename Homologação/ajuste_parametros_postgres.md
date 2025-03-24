# Ajuste de Parâmetros do PostgreSQL

## Descrição

Este script SQL interativo auxilia no ajuste de parâmetros do PostgreSQL, coletando informações sobre o tipo do banco de dados (OLTP, Analytics, Mixed Load, Desktop), localização (On-premise, EC2, RDS) e recursos de hardware (CPU, RAM, disco). Com base nessas informações, o script exibe os valores atuais e padrão de parâmetros importantes do PostgreSQL.

## Script

```sql
-- Para versões do Postgres anteriores a 10, copie/cole a parte
-- abaixo do último "\else" (role para baixo)

\set postgres_dba_t1_error false
\if :postgres_dba_interactive_mode
\echo
\echo 'Qual é o tipo do seu banco de dados?'
\echo '  1 – OLTP, Web/Mobile App'
\echo '  2 – Analytics, Data Warehouse'
\echo '  3 – Mixed Load'
\echo '  4 - Desktop / Máquina de Desenvolvedor'
\echo 'Digite sua escolha e pressione <Enter>: '
\prompt postgres_dba_t1_instance_type

SELECT :postgres_dba_t1_instance_type = 1 AS postgres_dba_t1_instance_type_oltp \gset
SELECT :postgres_dba_t1_instance_type = 2 AS postgres_dba_t1_instance_type_analytics \gset
SELECT :postgres_dba_t1_instance_type = 3 AS postgres_dba_t1_instance_type_mixed \gset
SELECT :postgres_dba_t1_instance_type = 4 AS postgres_dba_t1_instance_type_desktop \gset

\echo
\echo
\echo 'Onde a instância está localizada?'
\echo '  1 – On-premise'
\echo '  2 – Amazon EC2'
\echo '  3 – Amazon RDS'
\echo 'Digite sua escolha e pressione <Enter>: '
\prompt postgres_dba_t1_location

SELECT :postgres_dba_t1_location = 1 AS postgres_dba_t1_location_onpremise \gset
SELECT :postgres_dba_t1_location = 2 AS postgres_dba_t1_location_ec2 \gset
SELECT :postgres_dba_t1_location = 3 AS postgres_dba_t1_location_rds \gset

\echo
\echo

\if :postgres_dba_t1_location_onpremise
-- Mais perguntas para obter o número de núcleos de CPU, RAM, discos
\echo 'Digite o número de núcleos de CPU: '
\prompt postgres_dba_t1_cpu

\echo
\echo
\echo 'Digite a memória total disponível (em GB): '
\prompt postgres_dba_t1_memory

\echo
\echo
\echo 'Tipo de disco rígido?'
\echo '  1 - Armazenamento HDD'
\echo '  2 - Armazenamento SSD'
\echo 'Digite sua escolha e pressione <Enter>: '
\prompt postgres_dba_t1_location

\elif :postgres_dba_t1_location_ec2
-- CPU/memória/disco são conhecidos (AWS EC2)
\elif :postgres_dba_t1_location_rds
-- CPU/memória/disco são conhecidos (AWS RDS)
\else
\echo Erro! Opção impossível.
\set postgres_dba_t1_error true
\endif

\endif

\if :postgres_dba_t1_error
\echo Você inseriu uma entrada incorreta, não é possível prosseguir com este relatório. Pressione <Enter> para retornar ao menu
\prompt
\else
SELECT
    name AS "Parâmetro",
    CASE
        WHEN setting IN ('-1', '0', 'off', 'on') THEN setting
        ELSE
            CASE unit
                WHEN '8kB' THEN pg_size_pretty(setting::INT8 * 8 * 1024)
                WHEN '16MB' THEN pg_size_pretty(setting::INT8 * 16 * 1024 * 1024)
                WHEN 'kB' THEN pg_size_pretty(setting::INT8 * 1024)
                ELSE setting || COALESCE('', ' ' || unit)
            END
    END AS "Valor",
    CASE
        WHEN boot_val IN ('-1', '0', 'off', 'on') THEN boot_val
        ELSE
            CASE unit
                WHEN '8kB' THEN pg_size_pretty(boot_val::INT8 * 8 * 1024)
                WHEN '16MB' THEN pg_size_pretty(boot_val::INT8 * 16 * 1024 * 1024)
                WHEN 'kB' THEN pg_size_pretty(boot_val::INT8 * 1024)
                ELSE boot_val || COALESCE('', ' ' || unit)
            END
    END AS "Padrão",
    category AS "Categoria"
FROM pg_settings
WHERE
    name IN (
        'max_connections',
        'shared_buffers',
        'effective_cache_size',
        'maintenance_work_mem',
        'work_mem',
        'min_wal_size',
        'max_wal_size',
        'checkpoint_completion_target',
        'wal_buffers',
        'default_statistics_target',
        'random_page_cost',
        'effective_io_concurrency',
        'max_worker_processes',
        'max_parallel_workers_per_gather',
        'max_parallel_workers',
        'autovacuum_analyze_scale_factor',
        'autovacuum_max_workers',
        'autovacuum_vacuum_scale_factor',
        'autovacuum_work_mem',
        'autovacuum_naptime',
        'random_page_cost',
        'seq_page_cost'
    )
ORDER BY category, name;
\endif
```

## Explicação Detalhada

1.  **Coleta de Informações do Usuário**:
    * O script usa `\prompt` para solicitar informações do usuário sobre o tipo do banco de dados e a localização da instância.
    * Com base na localização, o script pode solicitar informações adicionais sobre os recursos de hardware (CPU, RAM, disco) se a instância for on-premise.

2.  **Tratamento de Erros**:
    * O script usa `\if` e `\set` para verificar se o usuário inseriu opções válidas.
    * Se o usuário inserir uma opção inválida, o script exibe uma mensagem de erro e define a variável `postgres_dba_t1_error` como `true`.

3.  **Exibição de Parâmetros**:
    * Se não houver erros, o script consulta a visão `pg_settings` para recuperar os valores atuais e padrão de parâmetros importantes do PostgreSQL.
    * O script usa `CASE` e `pg_size_pretty()` para formatar os valores dos parâmetros em um formato legível para humanos.
    * O script exibe os parâmetros, seus valores, valores padrão e categorias.

## Considerações

* O script é interativo e requer a entrada do usuário.
* O script adapta as perguntas e os parâmetros exibidos com base no tipo do banco de dados e na localização da instância.
* O script usa `pg_size_pretty()` para formatar os valores dos parâmetros de tamanho (por exemplo, `shared_buffers`, `work_mem`).
* O script exibe apenas um subconjunto de parâmetros importantes do PostgreSQL. Você pode modificar o script para exibir outros parâmetros conforme necessário.
* O script não aplica nenhuma recomendação de ajuste de parâmetros. Ele apenas exibe os valores atuais e padrão.
* Este script é muito útil para administradores de banco de dados que desejam ajustar os parâmetros do PostgreSQL para otimizar o desempenho.
