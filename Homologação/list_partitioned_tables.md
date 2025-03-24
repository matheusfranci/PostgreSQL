# Listar Tabelas com Detalhes no PostgreSQL

## Descrição

Este script SQL recupera informações sobre tabelas (normais e particionadas) em um banco de dados PostgreSQL. Ele fornece o nome do esquema, o nome da tabela, o tipo da tabela (normal ou particionada) e o proprietário da tabela. Ele exclui tabelas de sistema, como as que começam com `pg_` e as do esquema `information_schema`, bem como partições filhas.

## Query

```sql
SELECT
    n.nspname AS "Schema",
    c.relname AS "Name",
    CASE c.relkind
        WHEN 'p' THEN 'partitioned table'
        WHEN 'r' THEN 'ordinary table'
        ELSE 'unknown table type'
    END AS "Type",
    pg_catalog.pg_get_userbyid(c.relowner) AS "Owner"
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = ANY ('{p,r,""}')
AND NOT c.relispartition
AND n.nspname !~ ALL ('{^pg_,^information_schema$}')
ORDER BY 1, 2;
```

## Explicação Detalhada

* **`pg_catalog.pg_class c`**: Esta tabela do sistema contém informações sobre classes (tabelas, índices, etc.).
* **`pg_catalog.pg_namespace n`**: Esta tabela do sistema contém informações sobre esquemas.
* **`JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace`**: Junta as tabelas `pg_class` e `pg_namespace` usando o OID do namespace da classe (`c.relnamespace`) e o OID do namespace (`n.oid`).
* **`n.nspname AS "Schema"`**: Seleciona o nome do esquema e o renomeia para "Schema".
* **`c.relname AS "Name"`**: Seleciona o nome da tabela e o renomeia para "Name".
* **`CASE c.relkind ... END AS "Type"`**: Usa uma expressão `CASE` para determinar o tipo da tabela com base na coluna `c.relkind`:
    * `'p'` representa tabelas particionadas.
    * `'r'` representa tabelas normais (ordinárias).
    * Outros valores são rotulados como "unknown table type".
* **`pg_catalog.pg_get_userbyid(c.relowner) AS "Owner"`**: Recupera o nome do proprietário da tabela usando o OID do proprietário (`c.relowner`) e renomeia a coluna resultante para "Owner".
* **`WHERE c.relkind = ANY ('{p,r,""}')`**: Filtra os resultados para incluir apenas tabelas normais (`r`) e particionadas (`p`). O `ANY` permite incluir multiplos tipos de relkind.
* **`AND NOT c.relispartition`**: Filtra para excluir partições filhas, que são tabelas mas não devem ser listadas diretamente.
* **`AND n.nspname !~ ALL ('{^pg_,^information_schema$}')`**: Filtra os resultados para excluir tabelas dos esquemas do sistema (`pg_` e `information_schema`). O operador `!~` nega a correspondência com a expressão regular.
* **`ORDER BY 1, 2`**: Ordena os resultados pelo nome do esquema e pelo nome da tabela.

## Exemplos de Uso

Este script pode ser usado para:

* Obter uma lista de todas as tabelas (normais e particionadas) definidas pelo usuário em um banco de dados PostgreSQL.
* Identificar o tipo e o proprietário de cada tabela.
* Excluir tabelas de sistema e partições filhas da lista.
* Facilitar a análise e o gerenciamento de tabelas.

## Considerações

* A coluna `relkind` na tabela `pg_class` indica o tipo de objeto de banco de dados.
* A função `pg_get_userbyid()` recupera o nome do usuário com base no OID do usuário.
* As expressões regulares `^pg_` e `^information_schema$` excluem esquemas do sistema.
* A cláusula `NOT c.relispartition` garante que as partições filhas das tabelas particionadas não sejam incluídas.
* A ordenação dos resultados facilita a leitura e a análise.
* O tipo "unknown table type" pode aparecer caso existam outros tipos de tabelas que não foram previstas na query.
* Este script é muito útil para administradores de banco de dados e desenvolvedores que precisam gerenciar e analisar tabelas no PostgreSQL.
