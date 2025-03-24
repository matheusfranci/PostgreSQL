# Tabelas com Varreduras Sequenciais Excessivas no PostgreSQL

## Descrição

Este script SQL identifica tabelas no esquema `public` do PostgreSQL que mostram um padrão de varreduras sequenciais excessivas em relação a varreduras de índice. Ele fornece informações sobre o nome da tabela, o número total de varreduras sequenciais, o número total de varreduras de índice, o número de linhas na tabela e o tamanho da tabela.

## Query

```sql
SELECT
    relname AS TableName,
    TO_CHAR(seq_scan, '999,999,999,999') AS TotalSeqScan,
    TO_CHAR(idx_scan, '999,999,999,999') AS TotalIndexScan,
    TO_CHAR(n_live_tup, '999,999,999,999') AS TableRows,
    PG_SIZE_PRETTY(PG_RELATION_SIZE(relname::regclass)) AS TableSize
FROM pg_stat_all_tables
WHERE schemaname = 'public'
    AND 50 * seq_scan > idx_scan -- Mais de 2% de varreduras sequenciais
    AND n_live_tup > 10000
    AND PG_RELATION_SIZE(relname::regclass) > 5000000
ORDER BY relname ASC;
```

## Explicação Detalhada

* **`pg_stat_all_tables`**: Esta visão do sistema contém estatísticas sobre todas as tabelas no banco de dados.
* **`relname AS TableName`**: O nome da tabela.
* **`TO_CHAR(seq_scan, '999,999,999,999') AS TotalSeqScan`**: O número total de varreduras sequenciais formatado para melhor legibilidade.
* **`TO_CHAR(idx_scan, '999,999,999,999') AS TotalIndexScan`**: O número total de varreduras de índice formatado para melhor legibilidade.
* **`TO_CHAR(n_live_tup, '999,999,999,999') AS TableRows`**: O número de linhas vivas na tabela formatado para melhor legibilidade.
* **`PG_SIZE_PRETTY(PG_RELATION_SIZE(relname::regclass)) AS TableSize`**: O tamanho da tabela em um formato legível.
* **`WHERE schemaname = 'public'`**: Filtra tabelas no esquema `public`.
* **`AND 50 * seq_scan > idx_scan`**: Filtra tabelas onde o número de varreduras sequenciais é mais de 50 vezes maior que o número de varreduras de índice (ou seja, mais de aproximadamente 2% de sequenciais).
* **`AND n_live_tup > 10000`**: Filtra tabelas com mais de 10.000 linhas.
* **`AND PG_RELATION_SIZE(relname::regclass) > 5000000`**: Filtra tabelas com mais de 5 MB de tamanho.
* **`ORDER BY relname ASC`**: Ordena os resultados pelo nome da tabela em ordem crescente.

## Exemplos de Uso

Este script pode ser usado para:

* Identificar tabelas que podem se beneficiar da criação de índices para melhorar o desempenho das consultas.
* Otimizar consultas que estão realizando muitas varreduras sequenciais.
* Monitorar o desempenho das tabelas no esquema `public`.

## Considerações

* Varreduras sequenciais excessivas podem indicar que as consultas não estão usando índices eficientemente.
* A criação de índices apropriados pode reduzir o número de varreduras sequenciais e melhorar o desempenho das consultas.
* A decisão de criar índices deve ser baseada em uma análise cuidadosa dos padrões de consulta e da distribuição dos dados.
* Os filtros utilizados (50 * seq\_scan > idx\_scan, n\_live\_tup > 10000 e pg\_relation\_size > 5000000) podem ser ajustados conforme a necessidade.
* O resultado da query, indica as tabelas que provavelmente necessitam de índices.
