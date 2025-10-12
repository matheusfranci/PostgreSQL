# Procedimento de Instalação e Teste da Extensão `pg_repack` (PostgreSQL 17)

Este guia detalha os passos para instalar a extensão `pg_repack` a partir do código-fonte e demonstra sua eficácia na remoção de *bloat* (inchaço de tabelas) e na melhoria da performance de consultas.

## ⚠️ Erro Inicial: Extensão Não Disponível

O primeiro comando falha porque a extensão `pg_repack` não está instalada no sistema, nem seus arquivos de controle para que o PostgreSQL a reconheça:

```sql
qualitydb=# create extension pg_repack;
```

**Resultado:**

```
ERRO: a extensão "pg_repack" não está disponível
DETALHE: Não foi possível abrir o arquivo de controle de extensão "/usr/pgsql-17/share/extension/pg_repack.control": Arquivo ou diretório inexistente.
DICA: The extension must first be installed on the system where PostgreSQL is running.
```

-----

## 1\. Instalação e Compilação do `pg_repack`

### Passo 1: Preparar o Ambiente e Obter o Código-Fonte

Baixe o código-fonte oficial do projeto `pg_repack` e entre no diretório para a compilação.

```bash
cd ~/
git clone https://github.com/reorg/pg_repack.git
cd pg_repack
```

> **Nota:** O diretório `~/pg_repack` será usado para a compilação local.

### Passo 2: Adicionar o Repositório PGDG (PostgreSQL Global Development Group)

Adicione o repositório oficial que contém os pacotes e *headers* de desenvolvimento do PostgreSQL, essenciais para compilar extensões.

```bash
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/F-$(rpm -E %fedora)-x86_64/pgdg-fedora-repo-latest.noarch.rpm
```

### Passo 3: Instalar Dependências de Compilação

Instale as ferramentas de compilação (`make`, `gcc`) e as bibliotecas de desenvolvimento do PostgreSQL 17 (`postgresql17-devel`), além de bibliotecas de dependência.

```bash
sudo dnf install -y \
  postgresql17-devel \
  make gcc git \
  zlib-devel lz4-devel readline-devel openssl-devel libzstd-devel
```

> **Importante:** O pacote `postgresql17-devel` fornece o comando `pg_config` e os *headers* necessários para que a compilação saiba onde e como instalar a extensão para a versão 17.

### Passo 4: Compilar o `pg_repack`

Defina a variável de ambiente `PATH` para garantir que a compilação use o `pg_config` da versão 17 do PostgreSQL.

```bash
export PATH=/usr/pgsql-17/bin:$PATH
make clean
make
```

> O comando `make` gera o binário executável `pg_repack`.

### Passo 5: Instalar no Sistema

Copie os arquivos gerados para os diretórios corretos do PostgreSQL 17.

```bash
sudo env "PATH=$PATH" make install
```

Esta etapa copia:

  * O binário **`pg_repack`** para `/usr/pgsql-17/bin/` (para uso via linha de comando).
  * Os scripts SQL e arquivos de controle para `/usr/pgsql-17/share/extension/` (para o comando `CREATE EXTENSION` funcionar).

-----

## 2\. Verificação e Teste de Bloat

### Passo 6: Verificar a Instalação no Sistema e no Banco de Dados

1.  **Verificar Binário:**

    ```bash
    /usr/pgsql-17/bin/pg_repack --version
    ```

    **Resultado Esperado:**

    ```
    pg_repack 1.5.2
    ```

2.  **Instalar Extensões no Banco de Dados:**

    Conecte-se ao seu banco (`qualitydb`) e instale `pg_repack` e `pgstattuple` (usada para medir o *bloat*).

    ```sql
    CREATE EXTENSION pg_repack;
    CREATE EXTENSION pgstattuple;
    ```

3.  **Verificar Instalação (Catálogo):**

    ```sql
    \dx
    ```

    **Resultado Esperado (Parcial):**
    | Nome | Versão | Esquema | Descrição |
    | :--- | :--- | :--- | :--- |
    | **pg\_repack** | 1.5.2 | public | Reorganize tables in PostgreSQL databases with minimal locks |
    | **pgstattuple** | 1.5 | public | show tuple-level statistics |

### Passo 7: Criar Massa de Dados para Teste

Crie uma tabela e insira um grande volume de dados (100 milhões de linhas) para simular um ambiente de produção.

```sql
-- criando tabela para teste
CREATE TABLE test_pg_repack (
    id SERIAL PRIMARY KEY,
    data TEXT,
    created_at TIMESTAMP DEFAULT now()
);

-- inserindo massa (100 * 1M = 100.000.000 linhas)
DO $$
BEGIN
  FOR i IN 1..100 LOOP
    INSERT INTO test_pg_repack(data)
    SELECT md5(random()::text)
    FROM generate_series(1,1000000);  -- 1M por batch
  END LOOP;
END$$;
```

### Passo 8: Validar Bloat (Antes da Deleção)

Verifique o estado inicial da tabela. Note o baixo percentual de espaço livre (`free_percent`).

```sql
SELECT * FROM pgstattuple('test_pg_repack');
```

| table\_len | tuple\_count | tuple\_percent | dead\_tuple\_count | dead\_tuple\_percent | **free\_percent** |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 7.6GB | 100M | 94.04 | 0 | 0 | **0.39** |

### Passo 9: Gerar Bloat na Tabela

Execute comandos `DELETE` e `UPDATE` para criar tuplas "mortas" (*dead tuples*), gerando inchaço e fragmentação.

```sql
-- Deleta 70% das linhas para gerar bloat
DELETE FROM test_pg_repack
WHERE id % 10 < 7;

-- Atualiza linhas, gerando dead tuples
UPDATE test_pg_repack
SET data = md5(random()::text)
WHERE id % 10 >= 7;
```

### Passo 10: Validar Bloat (Após a Deleção/Atualização)

Verifique o estado da tabela após as operações. O `free_percent` (espaço livre) e `dead_tuple_percent` (tuplas mortas) devem aumentar significativamente.

```sql
SELECT * FROM pgstattuple('test_pg_repack');
```

| table\_len | tuple\_count | tuple\_percent | dead\_tuple\_count | **dead\_tuple\_percent** | **free\_percent** |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 7.6GB | 30M | 28.19 | 30M | **28.34** | **36.34** |

### Passo 11: Medir Performance (Antes do Repack)

Execute um `EXPLAIN ANALYZE` para medir o tempo de execução de uma consulta que faz varredura sequencial na tabela inchada.

```sql
EXPLAIN ANALYZE
SELECT COUNT(*) FROM test_pg_repack WHERE data LIKE 'a%';
```

**Resultado (Tempo de Execução):**

```
Execution Time: 13587.754 ms (~13.6 segundos)
```

-----

## 3\. Uso do `pg_repack` e Resultados

### Passo 12: Executar o `pg_repack`

Execute o utilitário na linha de comando para reorganizar a tabela `test_pg_repack` no banco de dados `qualitydb`.

```bash
/usr/pgsql-17/bin/pg_repack -t test_pg_repack qualitydb
```

**Resultado:**

```
INFO: repacking table "public.test_pg_repack"
```

### Passo 13: Validar a Redução de Bloat (Após o Repack)

Verifique a tabela novamente com `pgstattuple`. O tamanho da tabela (`table_len`) deve diminuir drasticamente, e os percentuais de tuplas mortas e espaço livre devem voltar ao normal.

```sql
SELECT * FROM pgstattuple('test_pg_repack');
```

| **table\_len** | tuple\_count | tuple\_percent | dead\_tuple\_count | dead\_tuple\_percent | free\_percent |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **2.2GB** | 30M | 94.04 | 0 | 0 | 0.39 |

> **Comparação:** O tamanho da tabela caiu de **7.6 GB** para **2.2 GB**.

### Passo 14: Medir Performance (Após o Repack)

Re-execute o `EXPLAIN ANALYZE` para medir a melhoria de performance da mesma consulta.

```sql
EXPLAIN ANALYZE
SELECT COUNT(*) FROM test_pg_repack WHERE data LIKE 'a%';
```

**Resultado (Tempo de Execução):**

```
Execution Time: 905.007 ms (~0.9 segundos)
```

**Conclusão do Teste:**

A execução do `pg_repack` resultou em uma redução de *bloat* de mais de 5 GB e uma melhoria de performance na consulta de varredura sequencial de **\~13.6 segundos para \~0.9 segundos**, demonstrando a eficácia da ferramenta.
