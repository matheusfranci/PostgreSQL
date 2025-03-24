# Tamanho do Tablespace Padrão no PostgreSQL

## Descrição

Esta query exibe o tamanho do tablespace padrão (`pg_default`) no PostgreSQL em um formato legível para humanos.

## Query

```sql
SELECT
    pg_size_pretty(
        pg_tablespace_size('pg_default')
    );
```

## Explicação Detalhada

* `pg_tablespace_size('pg_default')`: Esta função retorna o tamanho do tablespace especificado (neste caso, `pg_default`) em bytes.
* `pg_size_pretty(...)`: Esta função converte o tamanho em bytes para um formato legível para humanos (por exemplo, "GB", "MB", "KB").

## Exemplos de Uso

Esta query pode ser usada para:

* Monitorar o espaço em disco ocupado pelo tablespace padrão.
* Auxiliar na análise de espaço em disco.
* Verificar o tamanho do tablespace padrão em diferentes ambientes.

## Considerações

* O tablespace padrão (`pg_default`) é usado para armazenar objetos de banco de dados que não foram explicitamente atribuídos a outro tablespace.
* O tamanho exibido inclui todos os objetos armazenados no tablespace, como tabelas, índices e arquivos de controle.
* É importante monitorar o tamanho dos tablespaces ao longo do tempo para identificar tendências de crescimento e planejar a capacidade de armazenamento.
* Em ambientes com vários tablespaces, você pode adaptar esta query para verificar o tamanho de outros tablespaces, substituindo `'pg_default'` pelo nome do tablespace desejado.
* O tamanho retornado por essa query é o tamanho total do tablespace, incluindo espaço livre.
