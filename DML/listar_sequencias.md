# Listar Sequências no PostgreSQL

## Descrição

Este script SQL lista todas as sequências presentes em um banco de dados PostgreSQL. Ele fornece o esquema e o nome de cada sequência.

## Query

```sql
SELECT
    sequence_schema,
    sequence_name
FROM information_schema.sequences
ORDER BY sequence_name;
```

## Explicação Detalhada

* **`information_schema.sequences`**: Esta visão do sistema contém informações sobre sequências no banco de dados.
* **`sequence_schema`**: O nome do esquema onde a sequência está localizada.
* **`sequence_name`**: O nome da sequência.
* **`ORDER BY sequence_name`**: Ordena os resultados pelo nome da sequência em ordem crescente.

## Exemplos de Uso

Este script pode ser usado para:

* Obter uma lista de todas as sequências em um banco de dados.
* Identificar sequências específicas para gerenciamento ou análise.
* Verificar a existência de sequências em um esquema específico.

## Considerações

* As sequências são objetos de banco de dados usados para gerar sequências numéricas.
* Elas são comumente usadas para gerar valores de chave primária para tabelas.
* A visão `information_schema.sequences` fornece informações sobre todas as sequências que o usuário atual tem permissão para acessar.
* A ordenação por `sequence_name` facilita a localização de sequências específicas na lista.
* Este script é útil para listar todas as sequences do banco de dados.
