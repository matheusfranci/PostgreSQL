## Comandos Básicos no psql e Restart de Parâmetros

Este guia detalha os comandos básicos para interagir com o PostgreSQL através do psql e os procedimentos para restart de parâmetros.

### 1. Listando Bancos de Dados

Liste todos os bancos de dados no cluster:

```sql
\l
```

### 2. Listando Bancos de Dados com Detalhes

Liste os bancos de dados com informações detalhadas:

```sql
\l+
```

### 3. Conectando a um Banco de Dados

Conecte-se a um banco de dados específico no cluster:

```sql
\c database_name
```

### 4. Listando Tabelas

Liste todas as tabelas no banco de dados conectado:

```sql
\d+
```

### 5. Mostrando o Diretório de Dados

Mostre o diretório de dados do PostgreSQL dentro do psql:

```sql
show data_directory;
```

### 6. Restart de Parâmetros no PostgreSQL

Existem duas formas principais de restartar parâmetros no PostgreSQL:

* **Parâmetros Dinâmicos:**

    * Utilize o comando `pg_reload_conf()` para aplicar alterações em parâmetros dinâmicos sem reiniciar o serviço:

    ```sql
    SELECT pg_reload_conf();
    ```

* **Parâmetros Não Dinâmicos:**

    * Para parâmetros não dinâmicos, é necessário reiniciar o serviço PostgreSQL:

    ```bash
    systemctl restart postgresql.service
    ```
