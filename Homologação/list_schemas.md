# Listar Esquemas no PostgreSQL

## Descrição

Este script SQL recupera os nomes de todos os esquemas presentes em um banco de dados PostgreSQL.

## Query

```sql
SELECT schema_name
FROM information_schema.schemata;
```

## Explicação Detalhada

* **`information_schema.schemata`**: Esta visão do sistema contém informações sobre os esquemas no banco de dados.
* **`schema_name`**: O nome do esquema.
* **`SELECT schema_name`**: Seleciona o nome do esquema da visão `information_schema.schemata`.

## Exemplos de Uso

Este script pode ser usado para:

* Obter uma lista de todos os esquemas em um banco de dados.
* Identificar esquemas específicos para análise ou gerenciamento.
* Verificar a existência de esquemas no banco de dados.
* Listar todos os esquemas presentes no banco de dados.

## Considerações

* Os esquemas são namespaces que contêm objetos de banco de dados, como tabelas, views e funções.
* A visão `information_schema.schemata` fornece informações sobre todos os esquemas que o usuário atual tem permissão para acessar.
* A lista de esquemas pode incluir esquemas do sistema, como `pg_catalog` e `information_schema`.
* A ordenação dos resultados não é especificada, mas pode ser adicionada usando a cláusula `ORDER BY`.
* Este script é muito útil para listar todos os schemas de um banco de dados.
