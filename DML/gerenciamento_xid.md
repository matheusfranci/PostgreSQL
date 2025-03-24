# Gerenciamento de IDs de Transação (XIDs) no PostgreSQL

## Descrição

Este script SQL fornece informações sobre o risco de wraparound de XID no PostgreSQL. Ele calcula o XID mais antigo atual, a porcentagem em relação ao limite de wraparound e a porcentagem em relação ao limite de autovacuum de emergência. Ele também identifica tabelas com XIDs congelados antigos.

## Query 1: Risco de Wraparound de XID

```sql
WITH max_age AS (
    SELECT 2000000000 AS max_old_xid,
           setting AS autovacuum_freeze_max_age
    FROM pg_catalog.pg_settings
    WHERE name = 'autovacuum_freeze_max_age'
), per_database_stats AS (
    SELECT datname,
           m.max_old_xid::INT,
           m.autovacuum_freeze_max_age::INT,
           age(d.datfrozenxid) AS oldest_current_xid
    FROM pg_catalog.pg_database d
    JOIN max_age m ON (TRUE)
    WHERE d.datallowconn
)
SELECT MAX(oldest_current_xid) AS oldest_current_xid,
       MAX(ROUND(100 * (oldest_current_xid / max_old_xid::FLOAT))) AS percent_towards_wraparound,
       MAX(ROUND(100 * (oldest_current_xid / autovacuum_freeze_max_age::FLOAT))) AS percent_towards_emergency_autovac
FROM per_database_stats;
```

## Explicação Detalhada (Query 1)

* **`max_age` CTE**:
    * Define `max_old_xid` como 2 bilhões (o limite de wraparound).
    * Recupera o valor de `autovacuum_freeze_max_age` das configurações do PostgreSQL.
* **`per_database_stats` CTE**:
    * Calcula a idade do XID congelado mais antigo (`oldest_current_xid`) para cada banco de dados.
    * Filtra bancos de dados onde `datallowconn` é verdadeiro.
* **Consulta Principal**:
    * Calcula o XID congelado mais antigo geral.
    * Calcula a porcentagem em relação ao limite de wraparound.
    * Calcula a porcentagem em relação ao limite de autovacuum de emergência.

## Query 2: Tabelas com XIDs Congelados Antigos

```sql
SELECT relname,
       age(relfrozenxid),
       pg_size_pretty(pg_relation_size(oid)) AS SIZE
FROM pg_class
WHERE age(relfrozenxid) > 190000000
  AND relkind = 'r';
```

## Explicação Detalhada (Query 2)

* Recupera o nome da relação (`relname`), a idade do XID congelado (`age(relfrozenxid)`) e o tamanho da relação (`pg_size_pretty(pg_relation_size(oid))`) para tabelas (`relkind = 'r'`).
* Filtra tabelas com XIDs congelados com mais de 190 milhões de transações de idade.

## Exemplos de Uso

1.  **Verificar o risco geral de wraparound de XID:**

    ```sql
    -- Execute a Query 1
    ```

2.  **Identificar tabelas com XIDs congelados antigos:**

    ```sql
    -- Execute a Query 2
    ```

## Considerações

* O wraparound de XID ocorre quando o contador de XIDs atinge seu limite e volta a zero. Isso pode causar perda de dados se não for tratado adequadamente.
* O autovacuum do PostgreSQL ajuda a prevenir o wraparound de XID congelando XIDs antigos.
* O limite de `autovacuum_freeze_max_age` define quando o autovacuum inicia um congelamento agressivo.
* Tabelas com XIDs congelados antigos podem indicar que o autovacuum não está funcionando corretamente ou que as tabelas precisam ser reorganizadas.
* As informações das queries, permitem diagnosticar problemas relacionados ao XID, e tomar as medidas necessárias para prevenir a perda de dados.
* A query 2, permite identificar as tabelas que precisam de atenção.
