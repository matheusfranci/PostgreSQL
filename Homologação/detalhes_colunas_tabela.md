# Detalhes de Colunas de Tabelas no PostgreSQL

## Descrição

Ambos os scripts SQL recuperam informações sobre colunas de tabelas no PostgreSQL, incluindo o esquema da tabela, o nome da tabela, o nome da coluna e a descrição (comentário) associada à coluna. O primeiro script filtra os resultados para uma tabela específica (`YourTableName`), enquanto o segundo script recupera informações sobre todas as tabelas.

## Script 1: Detalhes de Colunas para uma Tabela Específica

```sql
SELECT
    c.table_schema,
    st.relname AS TableName,
    c.column_name,
    pgd.description
FROM pg_catalog.pg_statio_all_tables AS st
INNER JOIN information_schema.columns c
    ON c.table_schema = st.schemaname
    AND c.table_name = st.relname
LEFT JOIN pg_catalog.pg_description pgd
    ON pgd.objoid = st.relid
    AND pgd.objsubid = c.ordinal_position
WHERE st.relname = 'YourTableName';
```

### Explicação Detalhada

* **`pg_catalog.pg_statio_all_tables AS st`**: Esta visão do sistema contém estatísticas de E/S para todas as tabelas.
* **`information_schema.columns c`**: Esta visão do sistema contém informações sobre colunas de tabelas.
* **`pg_catalog.pg_description pgd`**: Esta tabela do sistema contém descrições (comentários) de objetos do banco de dados.
* **`INNER JOIN`**: As junções `INNER JOIN` combinam linhas das tabelas com base nas condições de junção.
* **`LEFT JOIN`**: A junção `LEFT JOIN` inclui todas as linhas da tabela `information_schema.columns` e as linhas correspondentes da tabela `pg_catalog.pg_description`, mesmo que não haja correspondência.
* **`WHERE st.relname = 'YourTableName'`**: Filtra os resultados para incluir apenas a tabela especificada.
* **`c.table_schema`**: O nome do esquema da tabela.
* **`st.relname AS TableName`**: O nome da tabela.
* **`c.column_name`**: O nome da coluna.
* **`pgd.description`**: A descrição (comentário) da coluna.

### Exemplos de Uso

Este script pode ser usado para:

* Obter informações detalhadas sobre as colunas de uma tabela específica.
* Visualizar os comentários associados às colunas da tabela.

## Script 2: Detalhes de Colunas para Todas as Tabelas

```sql
SELECT
    c.table_schema,
    c.table_name,
    c.column_name,
    pgd.description
FROM pg_catalog.pg_statio_all_tables AS st
INNER JOIN pg_catalog.pg_description pgd
    ON (pgd.objoid = st.relid)
INNER JOIN information_schema.columns c
    ON (pgd.objsubid = c.ordinal_position
        AND c.table_schema = st.schemaname
        AND c.table_name = st.relname);
```

### Explicação Detalhada

* A principal diferença deste script é que ele recupera informações sobre colunas de todas as tabelas, sem filtrar por uma tabela específica.
* As junções `INNER JOIN` garantem que apenas as colunas com descrições associadas sejam incluídas nos resultados.

### Exemplos de Uso

Este script pode ser usado para:

* Obter informações detalhadas sobre as colunas de todas as tabelas no banco de dados.
* Visualizar os comentários associados a todas as colunas de todas as tabelas.

## Considerações

* Ambos os scripts usam as tabelas do sistema `pg_catalog.pg_statio_all_tables`, `information_schema.columns` e `pg_catalog.pg_description` para recuperar as informações.
* O uso de `LEFT JOIN` no primeiro script garante que todas as colunas da tabela especificada sejam incluídas nos resultados, mesmo que não tenham comentários associados.
* O uso de `INNER JOIN` no segundo script garante que apenas as colunas com comentários associados sejam incluídas nos resultados.
* A coluna `pgd.description` pode ser nula se não houver um comentário associado à coluna.
* O primeiro script é mais adequado para obter informações sobre uma tabela específica, enquanto o segundo script é mais adequado para obter informações sobre todas as tabelas.
* O primeiro script utiliza o nome da tabela como `TableName`, enquanto o segundo utiliza `table_name`, ajuste conforme sua preferência.
