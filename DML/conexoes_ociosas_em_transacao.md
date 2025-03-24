# Conexões Ociosas em Transação no PostgreSQL

## Descrição

Esta consulta SQL recupera informações sobre conexões no PostgreSQL que estão ociosas dentro de uma transação (ou seja, iniciaram uma transação, mas não a finalizaram) e que têm um tempo de início de transação (`xact_start`) definido.

## Query

```sql
SELECT *
FROM pg_stat_activity
WHERE (state = 'idle in transaction')
AND xact_start IS NOT NULL;
```

## Explicação Detalhada

* **`pg_stat_activity`**: Esta tabela do sistema contém informações sobre a atividade atual de cada processo de servidor.
* **`state = 'idle in transaction'`**: Filtra as conexões para incluir apenas aquelas que estão ociosas dentro de uma transação.
* **`xact_start IS NOT NULL`**: Filtra as conexões para incluir apenas aquelas que têm um tempo de início de transação definido. Isso garante que a conexão realmente iniciou uma transação.
* **`SELECT *`**: Seleciona todas as colunas da tabela `pg_stat_activity` para fornecer informações detalhadas sobre as conexões ociosas.

## Exemplos de Uso

Esta consulta pode ser usada para:

* Identificar conexões que estão mantendo transações abertas desnecessariamente.
* Detectar possíveis problemas de bloqueio ou deadlock.
* Liberar recursos do banco de dados fechando transações ociosas.
* Monitorar conexões que podem estar causando problemas de desempenho.

## Considerações

* Conexões ociosas em transação podem manter bloqueios em tabelas e impedir que outras consultas sejam executadas.
* É importante investigar e finalizar essas transações ociosas para garantir o desempenho ideal do banco de dados.
* A coluna `xact_start` indica quando a transação foi iniciada, permitindo identificar transações de longa duração.
* A coluna `query` mostra a última consulta executada pela conexão, o que pode ajudar a identificar a causa da transação ociosa.
* É sempre importante ter cautela ao finalizar conexões ativas, pois isso pode interromper transações importantes.
* A consulta não mostra o conteúdo das transações, apenas que elas estão abertas e ociosas.
* Esta consulta pode ser combinada com outras consultas, para identificar o tempo que a transação está aberta, e assim, poder finalizar transações que ultrapassem um tempo limite.
