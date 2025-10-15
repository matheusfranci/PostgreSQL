## 🔒 Teste de Identificação de Locks de Linha com `pgrowlocks`

Este guia demonstra como utilizar a extensão `pgrowlocks` para visualizar bloqueios de linha ativos (`row-level locks`) e, em seguida, como criar uma função global para facilitar essa identificação em todo o banco de dados.

### 1\. Instalação e Verificação da Extensão

A extensão `pgrowlocks` é um **módulo contrib**, o que significa que geralmente não requer compilação e está pronta para ser instalada.

#### Passo 1.1: Instalar a Extensão

Execute o comando de criação no seu banco de dados:

```sql
CREATE EXTENSION pgrowlocks;
```

#### Passo 1.2: Verificar a Instalação

Confirme que a extensão foi instalada com sucesso:

```sql
\dx
```

**Resultado Esperado:** A listagem deve incluir `pgrowlocks`.

| name | version | schema | description |
| :--- | :--- | :--- | :--- |
| **pgrowlocks** | 1.2 | public | show row-level locking information |

-----

### 2\. Simulação de Lock de Linha

Para testar a extensão, vamos simular um bloqueio de linha mantendo uma transação de `UPDATE` aberta.

#### Passo 2.1: Criar e Popular a Tabela de Teste

Crie uma tabela simples e insira alguns registros:

```sql
CREATE TABLE lock_t (id serial PRIMARY KEY, val text);
INSERT INTO lock_t (val) VALUES ('a'), ('b'), ('c');
```

#### Passo 2.2: Iniciar o Bloqueio (Sessão 1)

Em uma **primeira sessão** (terminal ou cliente SQL), inicie uma transação e execute um `UPDATE`. **É crucial NÃO executar o `COMMIT` ou `ROLLBACK` neste momento.**

```sql
BEGIN;
UPDATE lock_t SET val = 'y' WHERE id = 1;
-- Mantenha esta transação aberta!
```

### 3\. Utilizando `pgrowlocks` na Tabela Específica

Em uma **segunda sessão** (outro terminal ou cliente SQL), iremos consultar o estado de locks da tabela `lock_t`.

#### Passo 3.1: Consultar Locks (Sessão 2)

Execute a função `pgrowlocks` passando o nome da tabela:

```sql
SELECT * FROM pgrowlocks('lock_t');
```

#### Resultado Esperado:

Você deve ver a linha bloqueada, o ID da transação (`locker`), o modo de bloqueio (`modes`), e o PID do processo que o está segurando (`pids`).

| locked\_row | locker | multi | xids | modes | pids |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **(0,1)** | 892 | f | {892} | **{"No Key Update"}** | **{1213}** |

-----

### 4\. Criando uma Função Global de Identificação

Se você não souber qual tabela está causando o lock, a consulta direta com `pgrowlocks('nome_da_tabela')` não será útil. Para isso, podemos criar uma função que verifica *todas* as tabelas que possuem locks de linha ativos e retorna os detalhes relevantes.

#### Passo 4.1: Criar a Função `pgrowlocks_global()`

Execute o código PL/pgSQL abaixo para criar a função:

```sql
CREATE OR REPLACE FUNCTION pgrowlocks_global()
RETURNS TABLE (
    table_name text,
    locked_row tid,
    lock_modes text[],
    pids int[],
    username text,
    query_text text,
    duration interval
)
LANGUAGE plpgsql
AS $$
DECLARE
    t record;
BEGIN
    FOR t IN
        SELECT DISTINCT format('%I.%I', n.nspname, c.relname) AS table_name
        FROM pg_locks l
        JOIN pg_class c ON l.relation = c.oid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE l.mode LIKE '%Row%'
          AND c.relkind IN ('r','p')
    LOOP
        RETURN QUERY EXECUTE format($f$
            SELECT
                '%s'::text AS table_name,
                r.locked_row,
                r.modes AS lock_modes,
                r.pids,
                a.usename::text AS username,
                a.query::text AS query_text,
                now() - a.query_start AS duration
            FROM pgrowlocks('%s') r
            LEFT JOIN pg_stat_activity a ON a.pid = ANY(r.pids)
            WHERE r.pids IS NOT NULL
        $f$, t.table_name, t.table_name);
    END LOOP;
END;
$$;
```

#### Passo 4.2: Executar a Consulta Global (Sessão 2)

Com a transação de `UPDATE` ainda aberta na **Sessão 1**, execute a nova função na **Sessão 2**:

```sql
SELECT * FROM pgrowlocks_global();
```

#### Resultado Esperado:

Esta função retorna uma visão completa, incluindo o nome da tabela, o usuário, o comando SQL exato que causou o lock e a duração da transação:

| table\_name | locked\_row | lock\_modes | pids | username | query\_text | duration |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **public.lock\_t** | (0,15) | **{"No Key Update"}** | **{1213}** | postgres | **UPDATE lock\_t SET val = 'y' WHERE id = 1;** | 00:00:51.863429 |

-----

### 5\. Finalização do Teste

Volte para a **Sessão 1** e finalize a transação. O lock será liberado.

```sql
COMMIT;
-- ou ROLLBACK;
```

Após o `COMMIT`, qualquer consulta feita na **Sessão 2** (seja `pgrowlocks('lock_t')` ou `pgrowlocks_global()`) retornará **vazio** (NULL ou nenhuma linha), indicando que os locks foram liberados.
