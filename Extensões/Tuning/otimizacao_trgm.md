````markdown
# Otimizando Consultas com `LIKE`/`ILIKE` em PostgreSQL Usando `pg_trgm`

Este procedimento demonstra como otimizar uma consulta com o operador `ILIKE` (insensível a maiúsculas/minúsculas) que utiliza o padrão de pesquisa inicial com `%` (ex: `'%texto%'`), forçando um **Seq Scan (Full Table Scan)**, e como utilizar a extensão **`pg_trgm`** para criar um índice **GIN (Generalized Inverted Index)**, resultando em uma otimização massiva de performance.

---

## 1. Configuração Inicial e Teste de Throughput (TPS)

### 1.1. Inserindo Massa de Dados para Teste com o Utilitário `pgbench`

O `pgbench` é uma ferramenta padrão do PostgreSQL para rodar testes de benchmark. O comando abaixo cria o esquema inicial e insere dados.

```bash
pgbench -i -s 1000 -n -d benchdbp
````

*Resultado (Exemplo):*

```
# Pode demorar dependendo da sua máquina e do scaling factor (-s)
```

### 1.2. Medindo a Capacidade de Throughput (TPS)

Este comando mede a capacidade de Throughput (TPS - Transações por Segundo) do seu PostgreSQL sob 10 conexões concorrentes, 2 threads, por 60 segundos.

```bash
pgbench -c 10 -j 2 -T 60 benchdbp
```

*Resultado (Exemplo):*

```
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1000
query mode: simple
number of clients: 10
number of threads: 2
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 54088
number of failed transactions: 0 (0.000%)
latency average = 11.092 ms
initial connection time = 20.525 ms
tps = 901.544725 (without initial connection time)
```

-----

## 2\. Teste de Performance Antes da Otimização

### 2.1. Atualizando uma Linha para Testar o `ILIKE`

Atualiza-se um registro na coluna `filler` da tabela `pgbench_accounts` para garantir que haja um resultado para a consulta.

```sql
UPDATE pgbench_accounts
SET filler = 'Matheus Valentim'
WHERE aid = 7073106;
```

### 2.2. Executando a Query com `EXPLAIN ANALYZE` (Antes do Índice)

A consulta utiliza `ILIKE '%valentim%'`, o que tipicamente impede o uso de índices padrão e força um **`Sequential Scan`** (varredura completa da tabela).

```sql
\timing on
benchdbp=# EXPLAIN ANALYZE
SELECT * FROM pgbench_accounts WHERE filler ILIKE '%valentim%';
```

*Resultado (Exemplo):*

```
                                                        QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..2162054.43 rows=1 width=97) (actual time=45165.324..45171.566 rows=1 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   ->  Parallel Seq Scan on pgbench_accounts  (cost=0.00..2161054.33 rows=1 width=97) (actual time=42090.398..45160.855 rows=0 loops=3)
         Filter: (filler ~~* '%valentim%'::text)
         Rows Removed by Filter: 33333333
 Planning Time: 0.083 ms
 Execution Time: 45171.668 ms
(8 linhas)

Tempo: 45172,334 ms (00:45,172)
```

**Observação:** O `Execution Time` foi de **45171.668 ms** (aproximadamente 45 segundos), confirmando o Sequential Scan (varredura completa).

-----

## 3\. Otimização com `pg_trgm` e Índice GIN

### 3.1. Adicionando a Extensão `pg_trgm`

A extensão `pg_trgm` fornece funções para determinar similaridade de texto com base em trigramas (sequências de três caracteres), permitindo o uso de índices em padrões de pesquisa flexíveis como `%texto%`.

```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

### 3.2. Criando o Índice GIN

Cria-se um índice **GIN (Generalized Inverted Index)** sobre a coluna `filler`, usando o operador de classe `gin_trgm_ops` fornecido pela extensão `pg_trgm`.

```sql
CREATE INDEX idx_filler_trgm ON pgbench_accounts USING gin (filler gin_trgm_ops);
```

### 3.3. Testando Novamente com `EXPLAIN ANALYZE` (Após o Índice)

A mesma consulta é executada. O otimizador de consultas do PostgreSQL agora pode usar o índice GIN.

```sql
benchdbp=# EXPLAIN ANALYZE
SELECT * FROM pgbench_accounts WHERE filler ILIKE '%valentim%';
```

*Resultado (Exemplo):*

```
                                                        QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on pgbench_accounts  (cost=18014.42..53750.56 rows=10000 width=44) (actual time=0.027..0.028 rows=1 loops=1)
   Recheck Cond: (filler ~~* '%valentim%'::text)
   Heap Blocks: exact=1
   ->  Bitmap Index Scan on idx_filler_trgm  (cost=0.00..18011.92 rows=10000 width=0) (actual time=0.009..0.009 rows=1 loops=1)
         Index Cond: (filler ~~* '%valentim%'::text)
 Planning Time: 2.205 ms
 Execution Time: 0.047 ms
(7 linhas)
```

## 4\. Conclusão da Otimização

O PostgreSQL deixou de realizar o **Full Table Scan (Sequential Scan)** e passou a utilizar o novo índice:

  * **Plano de Execução:** Agora é um **`Bitmap Heap Scan`** com um **`Bitmap Index Scan on idx_filler_trgm`**. O banco de dados usa o índice para localizar rapidamente os blocos (páginas) do *heap* (tabela) que contêm a linha desejada.
  * **Performance:** O `Execution Time` de **45171.668 ms** (aproximadamente 45 segundos) caiu para **0.047 ms**, tornando a consulta **quase instantânea**.

<!-- end list -->

```
```
