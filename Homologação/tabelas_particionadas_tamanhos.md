# Tabelas Particionadas e Tamanhos no PostgreSQL

## Descrição

Ambos os scripts SQL recuperam informações sobre tabelas particionadas no PostgreSQL, incluindo seus tamanhos. O primeiro script usa uma expressão CTE recursiva para identificar todas as partições de cada tabela pai, enquanto o segundo script usa `pg_inherits` e funções de tamanho para calcular os tamanhos das partições.

## Script 1: Tabelas Particionadas e Tamanhos Totais

```sql
WITH RECURSIVE tables AS (
    SELECT
        c.oid AS parent,
        c.oid AS relid,
        1 AS level
    FROM pg_catalog.pg_class c
    LEFT JOIN pg_catalog.pg_inherits AS i ON c.oid = i.inhrelid
    WHERE c.relkind IN ('p', 'r')
        AND i.inhrelid IS NULL
    UNION ALL
    SELECT
        p.parent AS parent,
        c.oid AS relid,
        p.level + 1 AS level
    FROM tables AS p
    LEFT JOIN pg_catalog.pg_inherits AS i ON p.relid = i.inhparent
    LEFT JOIN pg_catalog.pg_class AS c ON c.oid = i.inhrelid AND c.relispartition
    WHERE c.oid IS NOT NULL
)
SELECT
    parent::REGCLASS AS table_name,
    ARRAY_AGG(relid::REGCLASS) AS all_partitions,
    pg_size_pretty(SUM(pg_total_relation_size(relid))) AS pretty_total_size,
    SUM(pg_total_relation_size(relid)) AS total_size
FROM tables
GROUP BY parent
ORDER BY SUM(pg_total_relation_size(relid)) DESC;
```

### Explicação Detalhada

* **CTE `tables` (Recursiva)**:
    * Identifica as tabelas pai (particionadas ou não) que não são partições filhas.
    * Recursivamente, encontra todas as partições filhas de cada tabela pai.
    * `level` rastreia a profundidade da recursão.
* **Consulta Principal**:
    * Agrupa os resultados pelo `parent` (tabela pai).
    * Usa `ARRAY_AGG` para listar todas as partições de cada tabela pai.
    * Calcula e formata o tamanho total de todas as partições usando `pg_total_relation_size` e `pg_size_pretty`.
    * Ordena os resultados pelo tamanho total em ordem decrescente.

## Script 2: Detalhes de Tamanho de Tabelas Particionadas

```sql
SELECT
    pi.inhparent::regclass AS parent_table_name,
    pg_size_pretty(SUM(pg_total_relation_size(psu.relid))) AS total,
    pg_size_pretty(SUM(pg_relation_size(psu.relid))) AS internal,
    pg_size_pretty(SUM(pg_table_size(psu.relid) - pg_relation_size(psu.relid))) AS external,
    pg_size_pretty(SUM(pg_indexes_size(psu.relid))) AS indexes
FROM pg_catalog.pg_statio_user_tables psu
JOIN pg_class pc ON psu.relname = pc.relname
JOIN pg_database pd ON pc.relowner = pd.datdba
JOIN pg_inherits pi ON pi.inhrelid = pc.oid
WHERE pd.datname = 'migration'
GROUP BY pi.inhparent
ORDER BY SUM(pg_total_relation_size(psu.relid)) DESC;
```

### Explicação Detalhada

* **`pg_statio_user_tables`**: fornece estatísticas de I/O para tabelas de usuários.
* **`pg_class`**: contém informações sobre tabelas e outros objetos do banco de dados.
* **`pg_database`**: contém informações sobre bancos de dados.
* **`pg_inherits`**: lista as relações de herança (partições).
* **Funções de Tamanho**:
    * `pg_total_relation_size`: tamanho total da tabela (incluindo índices e TOAST).
    * `pg_relation_size`: tamanho apenas da tabela.
    * `pg_table_size`: tamanho da tabela e toast.
    * `pg_indexes_size`: tamanho dos índices.
    * `pg_size_pretty`: formata o tamanho para leitura humana.
* **`WHERE pd.datname = 'migration'`**: filtra os resultados para o banco de dados 'migration'.
* **`GROUP BY pi.inhparent`**: agrupa os resultados pela tabela pai.
* **`ORDER BY SUM(pg_total_relation_size(psu.relid)) DESC`**: ordena os resultados pelo tamanho total em ordem decrescente.

## Considerações

* O primeiro script fornece uma visão geral das tabelas particionadas e seus tamanhos totais, usando recursão para encontrar todas as partições.
* O segundo script fornece detalhes mais específicos sobre os tamanhos das partições, incluindo tamanhos internos, externos (TOAST) e de índices.
* O segundo script filtra os resultados para um banco de dados específico ('migration'). Remova a cláusula `WHERE` se você quiser resultados para todos os bancos de dados.
* Ambos os scripts são úteis para analisar o uso de espaço em tabelas particionadas no PostgreSQL.
* O primeiro script é mais genérico, enquanto o segundo é mais detalhado e específico para um banco de dados.
