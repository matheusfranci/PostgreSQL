# Recuperar Identidade de Réplica de Tabela no PostgreSQL

## Descrição

Este script SQL recupera a identidade de réplica de uma tabela específica no PostgreSQL. A identidade de réplica determina quais dados são usados para identificar linhas ao replicar atualizações e exclusões.

## Query

```sql
SELECT
    CASE relreplident
        WHEN 'd' THEN 'default'
        WHEN 'n' THEN 'nothing'
        WHEN 'f' THEN 'full'
        WHEN 'i' THEN 'index'
    END AS replica_identity
FROM pg_class
WHERE oid = 'mytablename'::regclass;
```

## Explicação Detalhada

* **`pg_class`**: Esta tabela do sistema contém informações sobre relações (tabelas, índices, etc.).
* **`relreplident`**: Uma coluna na tabela `pg_class` que indica a identidade de réplica da tabela.
* **`CASE relreplident ... END AS replica_identity`**: Uma expressão `CASE` que converte o valor de `relreplident` em uma string legível.
    * `'d'` -> `'default'`
    * `'n'` -> `'nothing'`
    * `'f'` -> `'full'`
    * `'i'` -> `'index'`
* **`WHERE oid = 'mytablename'::regclass`**: Filtra os resultados para a tabela específica com o nome `'mytablename'`. A conversão `'mytablename'::regclass` garante que a tabela seja identificada corretamente pelo seu OID.

## Exemplos de Uso

1.  **Recuperar a identidade de réplica da tabela `users`:**

    ```sql
    SELECT
        CASE relreplident
            WHEN 'd' THEN 'default'
            WHEN 'n' THEN 'nothing'
            WHEN 'f' THEN 'full'
            WHEN 'i' THEN 'index'
        END AS replica_identity
    FROM pg_class
    WHERE oid = 'users'::regclass;
    ```

2.  **Recuperar a identidade de réplica da tabela `orders`:**

    ```sql
    SELECT
        CASE relreplident
            WHEN 'd' THEN 'default'
            WHEN 'n' THEN 'nothing'
            WHEN 'f' then 'full'
            WHEN 'i' then 'index'
        END AS replica_identity
    FROM pg_class
    WHERE oid = 'orders'::regclass;
    ```

## Considerações

* A identidade de réplica é importante para a replicação lógica no PostgreSQL.
* `'default'` usa a chave primária da tabela (se existir) para identificar linhas.
* `'nothing'` indica que nenhuma informação de identificação de linha é usada.
* `'full'` usa todos os atributos (colunas) da tabela para identificar linhas.
* `'index'` usa o índice especificado para identificar linhas.
* A escolha da identidade de réplica afeta o desempenho e a quantidade de dados replicados.
* Se a tabela não existir, a consulta não retornará nenhuma linha.
* Para mudar a replica identity de uma tabela, utilize o comando `ALTER TABLE nome_tabela REPLICA IDENTITY tipo_replica;`
