# Análise do Uso de Índices em Tabelas de Usuário no PostgreSQL (Percentual)

## Descrição

Esta query analisa o uso de índices em tabelas de usuário no PostgreSQL, calculando a porcentagem de vezes que um índice é usado em relação a varreduras sequenciais e de índice. Ela também exibe o número de linhas em cada tabela.

## Query

```sql
SELECT relname,
       CASE idx_scan
           WHEN 0 THEN NULL
           ELSE round(100.0 * idx_scan / (seq_scan + idx_scan), 5)
       END percent_of_times_index_used,
       n_live_tup rows_in_table
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;
```

## Explicação Detalhada

* `pg_stat_user_tables`: Esta visão do sistema contém estatísticas sobre tabelas de usuário.
* `relname`: Nome da tabela.
* `idx_scan`: Número de varreduras de índice na tabela.
* `seq_scan`: Número de varreduras sequenciais na tabela.
* `n_live_tup`: Número de linhas ativas na tabela.
* `CASE idx_scan WHEN 0 THEN NULL ELSE round(100.0 * idx_scan / (seq_scan + idx_scan), 5) END percent_of_times_index_used`: Calcula a porcentagem de vezes que o índice é usado. Se `idx_scan` for 0, retorna `NULL`. Caso contrário, calcula a porcentagem, arredonda para 5 casas decimais e a exibe.
* `rows_in_table`: Alias para `n_live_tup`.
* `ORDER BY n_live_tup DESC`: Ordena os resultados pelo número de linhas em ordem decrescente.

## Exemplos de Uso

Esta query pode ser usada para:

* Avaliar a eficácia dos índices em tabelas de usuário.
* Identificar tabelas onde os índices são pouco utilizados.
* Otimizar consultas e melhorar o desempenho do banco de dados.
* Monitorar o uso de índices ao longo do tempo.

## Considerações

* Uma alta porcentagem de uso de índice indica que os índices estão sendo usados eficientemente.
* Uma baixa porcentagem de uso de índice pode indicar que os índices não estão sendo usados corretamente ou que as consultas precisam ser otimizadas.
* O valor `NULL` indica que a tabela ainda não foi analisada pelo coletor de estatísticas ou que não houve varreduras de índice.
* O número de linhas ativas (`n_live_tup`) pode não ser preciso em tabelas com muitas atualizações ou exclusões recentes.
* A query considera apenas varreduras de índice e varreduras sequenciais. Outros tipos de acesso (por exemplo, varreduras de bitmap) não são incluídos.
* O arredondamento da porcentagem para 5 casas decimais pode ajudar a identificar pequenas variações no uso do índice.
