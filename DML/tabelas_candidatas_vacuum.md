# Tabelas Candidatas a VACUUM no PostgreSQL

## Descrição

Este script SQL identifica tabelas no PostgreSQL que são candidatas a `VACUUM` com base no número de tuplas mortas (`n_dead_tup`) e nas configurações do `autovacuum` (`autovacuum_vacuum_scale_factor` e `autovacuum_vacuum_threshold`). Ele fornece informações sobre o nome do esquema, nome da tabela, número de tuplas vivas, número de tuplas mortas e a data da última execução do `autovacuum`.

## Query

```sql
SELECT
    schemaname,
    relname,
    n_live_tup,
    n_dead_tup,
    last_autovacuum
FROM pg_stat_all_tables
WHERE relname NOT LIKE 'pg_%'
ORDER BY
    n_dead_tup / (n_live_tup * current_setting('autovacuum_vacuum_scale_factor')::FLOAT8 + current_setting('autovacuum_vacuum_threshold')::FLOAT8) DESC
LIMIT 10;
```

## Explicação Detalhada

* **`pg_stat_all_tables`**: Esta visão do sistema contém estatísticas sobre todas as tabelas no banco de dados.
* **`schemaname`**: O nome do esquema da tabela.
* **`relname`**: O nome da tabela.
* **`n_live_tup`**: O número de tuplas vivas (linhas) na tabela.
* **`n_dead_tup`**: O número de tuplas mortas (linhas marcadas para exclusão, mas ainda não removidas) na tabela.
* **`last_autovacuum`**: A data e hora da última execução do `autovacuum` na tabela.
* **`WHERE relname NOT LIKE 'pg_%'`**: Filtra os resultados para excluir tabelas do sistema (tabelas cujo nome começa com `pg_`).
* **`current_setting('autovacuum_vacuum_scale_factor')::FLOAT8`**: Recupera o valor da configuração `autovacuum_vacuum_scale_factor` (fator de escala para autovacuum) e o converte para o tipo `FLOAT8`.
* **`current_setting('autovacuum_vacuum_threshold')::FLOAT8`**: Recupera o valor da configuração `autovacuum_vacuum_threshold` (limite para autovacuum) e o converte para o tipo `FLOAT8`.
* **`n_dead_tup / (n_live_tup * ... + ...)`**: Calcula uma métrica que representa a razão entre o número de tuplas mortas e o limite para autovacuum. Essa métrica é usada para identificar tabelas que são fortes candidatas a `VACUUM`.
* **`ORDER BY ... DESC`**: Ordena os resultados pela métrica calculada em ordem decrescente, para que as tabelas mais candidatas a `VACUUM` apareçam primeiro.
* **`LIMIT 10`**: Limita os resultados às 10 tabelas mais candidatas a `VACUUM`.

## Exemplos de Uso

Este script pode ser usado para:

* Identificar tabelas que podem se beneficiar da execução do comando `VACUUM`.
* Priorizar a execução do `VACUUM` em tabelas com alta quantidade de tuplas mortas.
* Monitorar a necessidade de `VACUUM` em tabelas do usuário.
* Auxiliar na otimização do desempenho do banco de dados.

## Considerações

* O comando `VACUUM` recupera espaço em disco ocupado por tuplas mortas e atualiza estatísticas de tabelas.
* Tabelas com um alto número de tuplas mortas podem sofrer de desempenho reduzido.
* O `autovacuum` do PostgreSQL executa o `VACUUM` automaticamente, mas este script pode ajudar a identificar tabelas que precisam de atenção imediata.
* As configurações `autovacuum_vacuum_scale_factor` e `autovacuum_vacuum_threshold` controlam o comportamento do `autovacuum`.
* A métrica calculada no script leva em consideração essas configurações para identificar tabelas que são fortes candidatas a `VACUUM`.
* O script exclui tabelas do sistema (`relname NOT LIKE 'pg_%'`) para focar em tabelas de usuário.
* A query lista as 10 tabelas que mais necessitam de VACUUM.
