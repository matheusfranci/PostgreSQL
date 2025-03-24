# Listar Views no Esquema Atual do PostgreSQL

## Descrição

Esta consulta SQL recupera os nomes de todas as views (visões) presentes nos esquemas atualmente definidos no `search_path` do PostgreSQL.

## Query

```sql
SELECT table_name
FROM INFORMATION_SCHEMA.views
WHERE table_schema = ANY (current_schemas(false));
```

## Explicação Detalhada

* **`INFORMATION_SCHEMA.views`**: Esta visão do sistema contém informações sobre views (visões) no banco de dados.
* **`table_name`**: O nome da view.
* **`WHERE table_schema = ANY (current_schemas(false))`**: Filtra os resultados para incluir apenas as views que estão localizadas nos esquemas retornados pela função `current_schemas(false)`.
    * **`current_schemas(false)`**: Esta função retorna um array contendo os nomes dos esquemas atualmente definidos no `search_path`. O argumento `false` indica que os esquemas do sistema (como `pg_catalog`) não devem ser incluídos.
    * **`ANY`**: Este operador compara o valor de `table_schema` com cada elemento do array retornado por `current_schemas(false)`.

## Exemplos de Uso

Este script pode ser usado para:

* Obter uma lista de todas as views nos esquemas atualmente visíveis para o usuário.
* Identificar views específicas para análise ou gerenciamento.
* Verificar a existência de views em esquemas específicos.

## Considerações

* O `search_path` define a ordem em que os esquemas são pesquisados quando um objeto de banco de dados é referenciado sem um nome de esquema explícito.
* A função `current_schemas(false)` retorna os esquemas que estão atualmente na `search_path` do usuário.
* Esta consulta é útil para listar as views presentes nos esquemas que o usuário está atualmente utilizando.
* Se o search path não estiver configurado, a query irá retornar as views do esquema public.
