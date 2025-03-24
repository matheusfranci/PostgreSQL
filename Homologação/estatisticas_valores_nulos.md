# Estatísticas de Valores Nulos em uma Coluna no PostgreSQL

## Descrição

Este script SQL calcula o número total de registros, o número de registros não nulos, o número de registros nulos e a porcentagem de registros não nulos em uma coluna específica de uma tabela no PostgreSQL.

## Query

```sql
SELECT
    COUNT(1) AS TotalAll,
    COUNT(<fieldname>) AS TotalNotNull,
    COUNT(1) - COUNT(<fieldname>) AS TotalNull,
    100.0 * COUNT(<fieldname>) / COUNT(1) AS PercentNotNull
FROM
    <tablename>;
```

## Explicação Detalhada

* **`COUNT(1) AS TotalAll`**: Calcula o número total de registros na tabela. `COUNT(1)` conta todas as linhas, independentemente de valores nulos.
* **`COUNT(<fieldname>) AS TotalNotNull`**: Calcula o número de registros onde a coluna `<fieldname>` não é nula. `COUNT()` ignora valores nulos.
* **`COUNT(1) - COUNT(<fieldname>) AS TotalNull`**: Calcula o número de registros onde a coluna `<fieldname>` é nula, subtraindo o número de registros não nulos do número total de registros.
* **`100.0 * COUNT(<fieldname>) / COUNT(1) AS PercentNotNull`**: Calcula a porcentagem de registros não nulos na coluna `<fieldname>`. A multiplicação por `100.0` garante que o resultado seja um número decimal.
* **`FROM <tablename>`**: Especifica a tabela na qual a consulta será executada.

## Instruções de Uso

* Substitua `<tablename>` pelo nome da tabela que você deseja analisar.
* Substitua `<fieldname>` pelo nome da coluna que você deseja analisar.

## Exemplos de Uso

Suponha que você tenha uma tabela chamada `clientes` com uma coluna chamada `email`. Para calcular as estatísticas de valores nulos na coluna `email`, você usaria a seguinte consulta:

```sql
SELECT
    COUNT(1) AS TotalAll,
    COUNT(email) AS TotalNotNull,
    COUNT(1) - COUNT(email) AS TotalNull,
    100.0 * COUNT(email) / COUNT(1) AS PercentNotNull
FROM
    clientes;
```

## Considerações

* Esta consulta é útil para identificar a quantidade de valores nulos em uma coluna e avaliar a integridade dos dados.
* A porcentagem de valores não nulos pode ajudar a determinar se uma coluna é adequada para uso em índices ou restrições `NOT NULL`.
* Se a coluna `<fieldname>` contiver apenas valores nulos, `TotalNotNull` será 0 e `PercentNotNull` será 0.0.
* Se a coluna `<fieldname>` não contiver nenhum valor nulo, `TotalNull` será 0 e `PercentNotNull` será 100.0.
* A query realiza um calculo de porcentagem, portanto o resultado de "PercentNotNull" será um valor decimal.
