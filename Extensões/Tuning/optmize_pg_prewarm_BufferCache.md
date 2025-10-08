# Otimizando o Desempenho com `pg_prewarm` no PostgreSQL

Este procedimento demonstra o uso da extensão `pg_prewarm` para carregar dados de uma tabela específica para o **Buffer Cache** compartilhado do PostgreSQL, comparando o tempo de execução de uma consulta antes e depois do pré-carregamento.

## 1\. Instalação das Extensões

Primeiro, instalamos as extensões necessárias para monitoramento e pré-carregamento.

```sql
-- Criação das extensões
CREATE EXTENSION IF NOT EXISTS pg_buffercache;
CREATE EXTENSION IF NOT EXISTS pg_prewarm;
```

-----

## 2\. Validação Inicial do Buffer Cache

Verificamos quais tabelas estão atualmente no **Buffer Cache**. Espera-se que a tabela `pgbench_accounts` esteja parcialmente em cache, pois foi utilizada recentemente (por exemplo, durante a geração de dados com `pgbench`).

```sql
-- Validando o Buffer Cache
SELECT
  c.relname AS table_name,
  COUNT(*) AS buffers,
  ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM pg_buffercache), 2) AS pct_cache
FROM pg_buffercache b
JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid)
JOIN pg_database d ON b.reldatabase = d.oid
WHERE d.datname = current_database()
  AND c.relkind = 'r'  -- apenas tabelas normais
GROUP BY c.relname
ORDER BY buffers DESC
LIMIT 20;
```

**Resultado (Exemplo após o uso da tabela):**

| `table_name` | `buffers` | `pct_cache` |
| :--- | :--- | :--- |
| `pgbench_accounts` | 2380 | 14.53 |

-----

## 3\. Teste de Desempenho Inicial (Com Dados em Cache Parcial)

Executamos um `SELECT` completo na tabela `pgbench_accounts` e analisamos o plano de execução e o tempo de retorno (`Execution Time`).

```sql
\timing on
EXPLAIN ANALYZE
SELECT * FROM pgbench_accounts;
\timing off
```

**Resultado do `EXPLAIN ANALYZE` (Exemplo com tempo de execução de \~827 ms):**

```
                                                        QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..263935.35 rows=10000035 width=97) (actual time=0.018..534.334 rows=10000000 loops=1)
 Planning Time: 0.122 ms
 Execution Time: 827.403 ms
```

-----

## 4\. Limpeza do Buffer Cache (Reiniciando o PostgreSQL)

Para simular um cenário onde a tabela não está em cache, o serviço do PostgreSQL é **reiniciado**.

Após a reinicialização, a validação do Buffer Cache mostra que a tabela `pgbench_accounts` não está mais presente (ou está com pouquíssimos *buffers*).

```sql
-- [Reinicie o serviço do PostgreSQL aqui]

-- Validando o Buffer Cache após o reinício
SELECT ... (a mesma query de validação) ...
```

**Resultado (Exemplo após o reinício):**

| `table_name` | `buffers` | `pct_cache` |
| :--- | :--- | :--- |
| `pg_attribute` | 41 | 0.25 |
| `pg_proc` | 20 | 0.12 |
| ... | ... | ... |
| `pgbench_accounts` | 0 | 0.00 |

-----

## 5\. Pré-Carregamento da Tabela com `pg_prewarm`

Utilizamos a função `pg_prewarm` para carregar a tabela `pgbench_accounts` para o Buffer Cache. O valor de retorno é o número de blocos (buffers) carregados.

```sql
SELECT pg_prewarm('pgbench_accounts');
```

**Resultado:**

```
 pg_prewarm
------------
     163935
(1 linha)
```

### Validação do Buffer Cache Pós-Pré-Carregamento

Verificamos que a tabela `pgbench_accounts` agora ocupa uma porção significativa do Buffer Cache.

```sql
-- Validando o Buffer Cache novamente
SELECT ... (a mesma query de validação) ...
```

**Resultado (Exemplo com alta porcentagem de cache para a tabela):**

| `table_name` | `buffers` | `pct_cache` |
| :--- | :--- | :--- |
| `pgbench_accounts` | 16312 | 99.56 |
| `pg_class` | 14 | 0.09 |
| ... | ... | ... |

-----

## 6\. Validação Final de Desempenho (Com Dados em Cache Total)

Executamos o mesmo `SELECT` novamente. Espera-se uma redução no `Execution Time` em comparação com o teste inicial, pois a maioria dos blocos de dados não precisou ser lida do disco rígido.

```sql
\timing on
EXPLAIN ANALYZE
SELECT * FROM pgbench_accounts;
\timing off
```

**Resultado do `EXPLAIN ANALYZE` (Exemplo com tempo de execução de \~727 ms - Redução de \~100ms):**

```
                                                        QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------
 Seq Scan on pgbench_accounts  (cost=0.00..263935.35 rows=10000035 width=97) (actual time=0.021..457.123 rows=10000000 loops=1)
 Planning Time: 0.035 ms
 Execution Time: 727.327 ms
```

**Conclusão:** O uso de **`pg_prewarm`** pré-carregou a tabela para o Buffer Cache do PostgreSQL, resultando em uma redução notável no **Tempo de Execução** (de 827.403 ms para 727.327 ms no exemplo), demonstrando sua eficácia para otimizar a leitura de dados de tabelas críticas.
