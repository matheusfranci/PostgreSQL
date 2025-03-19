# Gerenciamento de Schemas no PostgreSQL

Este documento fornece exemplos de como criar, deletar, definir o `search_path` e mover tabelas entre schemas no PostgreSQL.

## Criar Schema

Para criar um novo schema, utilize o seguinte comando:

### Comando

```sql
CREATE SCHEMA nome_do_schema;
```

### Exemplo

```sql
CREATE SCHEMA schemaname;
```

### Descrição

Este comando cria um novo schema com o nome especificado.

## Deletar Schema

Para deletar um schema existente, utilize o seguinte comando:

### Comando

```sql
DROP SCHEMA nome_do_schema;
```

### Exemplo

```sql
DROP SCHEMA schemaname;
```

### Descrição

Este comando remove o schema com o nome especificado.

## Definir o Schema Padrão (`search_path`)

O `search_path` define a ordem em que o PostgreSQL procura por objetos (tabelas, funções, etc.) quando o schema não é especificado na consulta
