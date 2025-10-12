# Procedimento de Teste: Instalação e Uso do `pg_hint_plan`

Este guia detalha a instalação da extensão `pg_hint_plan` e demonstra seu uso para forçar um plano de execução de consulta específico (Index Scan) no PostgreSQL.

## 1\. Instalação e Configuração da Extensão

Esta seção abrange o *download*, a compilação e a ativação da extensão `pg_hint_plan`.

### 1.1. Preparação e *Download*

1.  Acesse o diretório de código-fonte:

    ```bash
    cd /usr/local/src
    ```

2.  Clone o repositório oficial do `pg_hint_plan`:

    ```bash
    sudo git clone https://github.com/ossc-db/pg_hint_plan.git
    ```

3.  Entre no diretório do projeto:

    ```bash
    cd pg_hint_plan
    ```

4.  Instale as dependências de compilação (**`flex`** e **`bison`**):

    ```bash
    sudo dnf install flex bison -y
    ```

### 1.2. Compilação e Instalação

1.  Compile o código-fonte (certifique-se de que o caminho para **`pg_config`** está correto para a sua versão, aqui usada a `17`):

    ```bash
    make PG_CONFIG=/usr/pgsql-17/bin/pg_config
    ```

2.  Instale a extensão no sistema (também usando o caminho correto para o `pg_config`):

    ```bash
    sudo make install PG_CONFIG=/usr/pgsql-17/bin/pg_config
    ```

### 1.3. Ativação no PostgreSQL

1.  Edite o arquivo de configuração principal do PostgreSQL (`postgresql.conf`) e adicione a extensão na lista de bibliotecas pré-carregadas:

    ```conf
    # Adicione esta linha ao postgresql.conf
    shared_preload_libraries = 'pg_hint_plan'
    ```

2.  **Reinicie o serviço** do PostgreSQL para que a alteração tenha efeito:

    ```bash
    sudo systemctl restart postgresql-17
    ```

-----

## 2\. Configuração no Banco de Dados (PSQL)

Após o reinício do servidor, a extensão deve ser ativada no banco de dados.

1.  Conecte-se ao `psql` e execute o comando para criar a extensão:

    ```sql
    CREATE EXTENSION pg_hint_plan;
    ```

2.  **Verifique a instalação** usando o comando `\dx`:

    ```sql
    \dx
    ```

    Você deve ver a extensão listada:
    | Nome | Versão | ... | Descrição |
    | :--- | :--- | :--- | :--- |
    | **pg\_hint\_plan** | 1.7.1 | ... | optimizer hints for PostgreSQL |

-----

## 3\. Preparação do Ambiente de Teste

Para demonstrar o funcionamento do `pg_hint_plan`, criaremos uma tabela grande e um índice.

1.  Crie a tabela **`clientes`**:

    ```sql
    CREATE TABLE clientes (
        id SERIAL PRIMARY KEY,
        nome TEXT,
        idade INT,
        cidade TEXT
    );
    ```

2.  Gere **100 milhões de linhas** para simular um volume grande de dados:

    ```sql
    -- Gera 100 milhões de linhas
    INSERT INTO clientes (nome, idade, cidade)
    SELECT
        'Cliente_' || g,
        (random() * 80)::int,
        CASE (random() * 5)::int
            WHEN 0 THEN 'São Paulo'
            WHEN 1 THEN 'Rio de Janeiro'
            WHEN 2 THEN 'Belo Horizonte'
            WHEN 3 THEN 'Curitiba'
            ELSE 'Recife'
        END
    FROM generate_series(1, 100000000) g;
    ```

3.  Crie um índice na coluna **`cidade`**:

    ```sql
    CREATE INDEX idx_clientes_cidade ON clientes(cidade);
    ```

4.  Execute **`ANALYZE`** para atualizar as estatísticas do planejador de consultas:

    ```sql
    ANALYZE clientes;
    ```

-----

## 4\. Teste de Forçamento do Plano

Agora vamos comparar o plano de execução padrão do PostgreSQL com o plano forçado pelo `pg_hint_plan`.

### 4.1. Plano de Execução Padrão (Seq Scan)

O PostgreSQL, por conta própria, pode decidir que um *Seq Scan* (leitura sequencial de toda a tabela) é mais rápido do que um *Index Scan* para o volume de dados e o critério de seleção.

```sql
EXPLAIN ANALYZE
SELECT * FROM clientes WHERE cidade = 'Curitiba';
```

**Resultado Típico (Exemplo):**

| QUERY PLAN |
| :--- |
| **Seq Scan** on clientes (cost=0.00..2118066.90 **rows=20221811** width=34) ... |
| Planning Time: 1.751 ms |
| **Execution Time: 25716.782 ms** |

*Neste caso, o planejador optou por ler a tabela inteira (`Seq Scan`).*

### 4.2. Plano de Execução Forçado (Index Scan)

Usaremos o comentário especial `/*+ ... */` do `pg_hint_plan` para **forçar** o planejador a usar o índice **`idx_clientes_cidade`**.

```sql
EXPLAIN ANALYZE
SELECT /*+ IndexScan(clientes idx_clientes_cidade) */
    * FROM clientes WHERE cidade = 'Curitiba';
```

**Resultado Típico (Exemplo):**

| QUERY PLAN |
| :--- |
| **Index Scan** using **idx\_clientes\_cidade** on clientes (cost=0.57..35754349.30 **rows=20221811** width=34) ... |
| Planning Time: 8.989 ms |
| **Execution Time: 18275.576 ms** |

*Ao forçar o uso do índice (`Index Scan`), a **Execution Time** (tempo de execução) **diminuiu** (de 25716ms para 18275ms), demonstrando o controle que a extensão oferece sobre o planejador de consultas.*
