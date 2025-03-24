# Tamanho das Tabelas TOAST no PostgreSQL

## Descrição

Esta query lista o tamanho das tabelas TOAST associadas a tabelas de usuário no PostgreSQL. Tabelas TOAST são usadas para armazenar valores grandes (como texto longo ou dados binários) que não cabem nas páginas de dados normais.

## Query

```sql
SELECT c.relname AS name,
       pg_size_pretty(pg_total_relation_size(reltoastrelid)) AS toast_size
FROM pg_class c
LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND n.nspname !~ '^pg_toast'
  AND c.relkind = 'r'
ORDER BY pg_total_relation_size(reltoastrelid) DESC NULLS LAST;
```

## Explicação Detalhada

* `pg_class c`: Tabela do sistema que contém informações sobre relações (tabelas e índices).
* `pg_namespace n`: Tabela do sistema que contém informações sobre namespaces (esquemas).
* `c.relname AS name`: Nome da tabela principal.
* `pg_size_pretty(pg_total_relation_size(reltoastrelid)) AS toast_size`: Tamanho da tabela TOAST associada à tabela principal em formato legível para humanos.
    * `pg_total_relation_size(reltoastrelid)`: Função que retorna o tamanho total da relação TOAST em bytes.
* `LEFT JOIN pg_namespace n ON n.oid = c.relnamespace`: Junta `pg_class` com `pg_namespace` para obter o nome do esquema.
* `WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')`: Exclui tabelas dos esquemas do sistema.
* `AND n.nspname !~ '^pg_toast'`: Exclui tabelas TOAST diretamente.
* `AND c.relkind = 'r'`: Filtra para incluir apenas tabelas regulares (não índices, views, etc.).
* `ORDER BY pg_total_relation_size(reltoastrelid) DESC NULLS LAST`: Ordena os resultados pelo tamanho da tabela TOAST em ordem decrescente, colocando valores `NULL` no final.

## Exemplos de Uso

Esta query pode ser usada para:

* Identificar tabelas que armazenam grandes quantidades de dados TOAST.
* Monitorar o espaço em disco ocupado por dados TOAST.
* Auxiliar na análise de espaço em disco.
* Identificar tabelas que podem precisar de otimização no armazenamento de valores grandes.

## Considerações

* Tabelas TOAST são criadas automaticamente para tabelas que contêm colunas com tipos de dados que podem armazenar valores grandes.
* O tamanho da tabela TOAST indica a quantidade de espaço em disco ocupado pelos valores grandes armazenados na tabela.
* A query exclui tabelas do sistema e tabelas TOAST diretamente.
* A ordenação coloca tabelas com os maiores tamanhos TOAST no topo da lista.
* A ordenação coloca valores nulos no final da lista, para que as tabelas que não possuem dados TOAST não interfiram nos resultados.
