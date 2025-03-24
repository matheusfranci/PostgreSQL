# Recuperar Chaves Estrangeiras no Esquema Público do PostgreSQL

## Descrição

Este script SQL recupera informações sobre chaves estrangeiras no esquema `public` do PostgreSQL. Ele fornece o nome da tabela, o nome da chave estrangeira e a definição da chave estrangeira.

## Query

```sql
SELECT
    conrelid::regclass AS table_name,
    conname AS foreign_key,
    pg_get_constraintdef(oid)
FROM pg_constraint
WHERE contype = 'f'
    AND connamespace = 'public'::regnamespace
ORDER BY conrelid::regclass::text, contype DESC;
```

## Explicação Detalhada

* **`pg_constraint`**: Esta tabela do sistema contém informações sobre restrições (constraints) em tabelas.
* **`conrelid::regclass AS table_name`**: O nome da tabela que contém a chave estrangeira. A conversão `conrelid::regclass` garante que o OID da tabela seja convertido corretamente em um nome legível.
* **`conname AS foreign_key`**: O nome da chave estrangeira.
* **`pg_get_constraintdef(oid)`**: A definição da chave estrangeira, incluindo as colunas referenciadas e a tabela referenciada.
* **`WHERE contype = 'f'`**: Filtra os resultados para restrições do tipo chave estrangeira (`f`).
* **`AND connamespace = 'public'::regnamespace`**: Filtra os resultados para restrições no esquema `public`. A conversão `'public'::regnamespace` garante que o OID do esquema `public` seja usado corretamente.
* **`ORDER BY conrelid::regclass::text, contype DESC`**: Ordena os resultados pelo nome da tabela em ordem crescente e pelo tipo de restrição em ordem decrescente (neste caso, todas são chaves estrangeiras, então o segundo critério de ordenação não tem efeito significativo).

## Exemplos de Uso

Este script pode ser usado para:

* Listar todas as chaves estrangeiras em tabelas no esquema `public`.
* Obter a definição de uma chave estrangeira específica.
* Auxiliar na análise e manutenção do esquema do banco de dados.

## Considerações

* Certifique-se de que o esquema `public` exista no seu banco de dados.
* A definição da chave estrangeira (`pg_get_constraintdef(oid)`) fornece informações detalhadas sobre a restrição, incluindo as colunas referenciadas e a tabela referenciada.
* Caso não existam chaves estrangeiras no esquema public, a query não retornará dados.
* Para verificar chaves estrangeiras de outros schemas, altere o valor de `connamespace`.
