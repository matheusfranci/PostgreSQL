# Últimos Autovacuums em Tabelas de Usuário no PostgreSQL

## Descrição

Esta consulta SQL recupera o nome da tabela (`relname`), a última vez que a tabela foi explicitamente vacuada (`last_vacuum`) e a última vez que a tabela foi automaticamente vacuada (`last_autovacuum`) para as 10 tabelas de usuário mais recentemente autovacuadas. Ela filtra as tabelas para incluir apenas aquelas que foram autovacuadas (ou seja, `last_autovacuum` não é nulo) e ordena os resultados pela data e hora do último autovacuum em ordem decrescente.

## Query

```sql
SELECT relname, last_vacuum, last_autovacuum
FROM pg_stat_user_tables
WHERE last_autovacuum IS NOT NULL
ORDER BY last_autovacuum DESC
LIMIT 10;
```

## Explicação Detalhada

* **`pg_stat_user_tables`**: Esta visão do sistema contém estatísticas sobre tabelas definidas pelo usuário.
* **`relname`**: O nome da tabela.
* **`last_vacuum`**: A última vez que a tabela foi explicitamente vacuada.
* **`last_autovacuum`**: A última vez que a tabela foi automaticamente vacuada.
* **`WHERE last_autovacuum IS NOT NULL`**: Filtra os resultados para incluir apenas tabelas que foram autovacuadas.
* **`ORDER BY last_autovacuum DESC`**: Ordena os resultados pela data e hora do último autovacuum em ordem decrescente.
* **`LIMIT 10`**: Limita os resultados às 10 tabelas mais recentemente autovacuadas.

## Exemplos de Uso

Esta consulta pode ser usada para:

* Monitorar a atividade do `autovacuum` em tabelas de usuário.
* Identificar tabelas que estão sendo autovacuadas com frequência.
* Verificar se o `autovacuum` está funcionando corretamente.
* Auxiliar na otimização das configurações do `autovacuum`.
* Identificar se o autovacuum está conseguindo acompanhar a carga de deleções e updates.

## Considerações

* O `autovacuum` é um processo importante no PostgreSQL que recupera espaço em disco e atualiza estatísticas de tabelas.
* Tabelas que são atualizadas ou excluídas com frequência podem exigir autovacuum mais frequente.
* A coluna `last_vacuum` pode ser útil para identificar tabelas que foram explicitamente vacuadas, o que pode afetar o comportamento do `autovacuum`.
* A consulta retorna apenas as 10 tabelas mais recentes, caso necessite de mais informações, remova a cláusula `LIMIT 10`.
* Caso a coluna `last_autovacuum` seja nula para todas as tabelas, verifique se o autovacuum está habilitado no seu banco de dados.
