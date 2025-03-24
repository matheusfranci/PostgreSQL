# Estatísticas de Bancos de Dados no PostgreSQL

## Descrição

Esta consulta SQL recupera informações estatísticas sobre os bancos de dados no PostgreSQL. Ela fornece detalhes sobre o número de conexões, conflitos, tuplas lidas e escritas, e outros dados relevantes para monitorar o desempenho do banco de dados.

## Query

```sql
SELECT *
FROM pg_stat_database;
```

## Explicação Detalhada

* **`pg_stat_database`**: Esta visão do sistema contém estatísticas sobre cada banco de dados no cluster PostgreSQL.
* **`SELECT *`**: Seleciona todas as colunas da visão `pg_stat_database`.

## Colunas Relevantes

A visão `pg_stat_database` contém várias colunas, incluindo:

* **`datid`**: O OID do banco de dados.
* **`datname`**: O nome do banco de dados.
* **`numbackends`**: O número de conexões ativas com o banco de dados.
* **`xact_commit`**: O número de transações confirmadas.
* **`xact_rollback`**: O número de transações revertidas.
* **`blks_read`**: O número de blocos de disco lidos.
* **`blks_hit`**: O número de blocos de disco encontrados no cache.
* **`tup_returned`**: O número de tuplas retornadas por consultas.
* **`tup_fetched`**: O número de tuplas buscadas por consultas.
* **`tup_inserted`**: O número de tuplas inseridas.
* **`tup_updated`**: O número de tuplas atualizadas.
* **`tup_deleted`**: O número de tuplas excluídas.
* **`conflicts`**: O número de consultas canceladas devido a conflitos de recuperação.
* **`temp_files`**: O número de arquivos temporários criados por consultas.
* **`temp_bytes`**: O número total de bytes escritos em arquivos temporários.
* **`deadlocks`**: O número de deadlocks detectados.
* **`blk_read_time`**: O tempo gasto lendo blocos de disco (em milissegundos).
* **`blk_write_time`**: O tempo gasto escrevendo blocos de disco (em milissegundos).
* **`stats_reset`**: O horário em que as estatísticas foram redefinidas pela última vez.

## Exemplos de Uso

Este script pode ser usado para:

* Monitorar o número de conexões ativas com cada banco de dados.
* Analisar o desempenho do banco de dados, observando o número de leituras/gravações de disco e o número de tuplas processadas.
* Identificar bancos de dados com alta atividade ou problemas de desempenho.
* Monitorar deadlocks e conflitos.
* Verificar o tamanho de arquivos temporários.
* Obter um panorama geral da atividade do banco de dados.

## Considerações

* As estatísticas são redefinidas quando o servidor PostgreSQL é reiniciado ou quando o comando `pg_stat_reset()` é executado.
* As estatísticas fornecidas por `pg_stat_database` são úteis para monitorar o desempenho do banco de dados em tempo real.
* Para monitorar o desempenho de um banco de dados específico, você pode filtrar os resultados usando a cláusula `WHERE datname = 'nome_do_banco_de_dados'`.
* As colunas `blk_read_time` e `blk_write_time` podem não estar disponíveis em todas as plataformas.
* Essa query fornece uma visão geral do banco de dados, para detalhes das tabelas, utilize `pg_stat_user_tables`.
