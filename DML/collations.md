# Collations en_US no PostgreSQL

## Descrição

Esta consulta SQL recupera todas as collations (regras de ordenação) do PostgreSQL cujo nome contém a string `en_US`. Collations definem como os dados são ordenados e comparados, e `en_US` representa o locale Inglês dos Estados Unidos.

## Query

```sql
SELECT *
FROM pg_collation
WHERE collname LIKE '%en_US%';
```

## Explicação Detalhada

* **`pg_collation`**: Esta tabela do sistema contém informações sobre collations disponíveis no banco de dados.
* **`collname`**: O nome da collation.
* **`WHERE collname LIKE '%en_US%'`**: Filtra os resultados para incluir apenas collations cujo nome contém a string `en_US`. O operador `LIKE` com o caractere curinga `%` permite encontrar collations com `en_US` em qualquer posição do nome.
* **`SELECT *`**: Seleciona todas as colunas da tabela `pg_collation`, exibindo detalhes como o OID da collation, o esquema, o locale LC_COLLATE e LC_CTYPE.

## Exemplos de Uso

Este script pode ser usado para:

* Listar todas as collations específicas para o locale `en_US`.
* Verificar a disponibilidade de collations `en_US` no banco de dados.
* Identificar as configurações de locale associadas às collations `en_US`.
* Auxiliar na configuração de collations para colunas de texto em tabelas.

## Considerações

* Collations são importantes para garantir a ordenação e comparação correta de dados textuais.
* Diferentes collations podem produzir resultados diferentes para a mesma consulta.
* O locale `en_US` é comumente usado para dados em inglês dos Estados Unidos.
* A consulta retorna todas as colunas da tabela `pg_collation`, permitindo uma análise detalhada das collations.
* O uso de `LIKE` permite encontrar collations com variações de `en_US` no nome.
* A saída desta query depende das collations instaladas no sistema operacional e no PostgreSQL.
