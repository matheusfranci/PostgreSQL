# Procedure PL/pgSQL para Limpeza de E-mails em Lotes

## Descrição

Esta procedure PL/pgSQL chamada `scrub_email_batch` realiza a limpeza de endereços de e-mail em lotes em uma tabela específica. Ela itera sobre os registros da tabela em lotes de um tamanho especificado, captura o endereço de e-mail original, o limpa (atualmente substituindo por um valor estático) e atualiza o registro com o endereço de e-mail limpo.

## Procedure

```sql
CREATE OR REPLACE PROCEDURE scrub_email_batch(_tbl REGCLASS, _col VARCHAR(255))
LANGUAGE plpgsql
AS $$
DECLARE
    batch_size INT := 50;
    orig_email VARCHAR(255);
    scrubbed_email VARCHAR(255);
    min_id BIGINT;
    max_id BIGINT;
BEGIN
    EXECUTE FORMAT('SELECT MAX(id), MIN(id) FROM %s', _tbl) INTO max_id, min_id;
    RAISE INFO 'table=% column=% max_id=% min_id=%', _tbl, _col, max_id, min_id;

    FOR j IN min_id..max_id BY batch_size LOOP
        FOR k IN j..j + batch_size LOOP
            -- 1) capture original email
            -- %L with format will use it literally
            EXECUTE FORMAT('SELECT %s FROM %s WHERE id = %s', _col, _tbl, k) INTO orig_email;
            CONTINUE WHEN orig_email IS NULL;
            RAISE INFO 'orig % ', orig_email;

            -- 2) update emails individually for each in batch_size
            -- quote_literal() supplies the value quoted in the statement
            EXECUTE FORMAT('UPDATE %s SET %s = %s WHERE id = %s', _tbl, _col, QUOTE_LITERAL('xyz@example.com'), k);
        END LOOP;

        RAISE INFO 'committing batch from % to % at %', j, j + batch_size, NOW();
        COMMIT;
    END LOOP; -- batch loop
END;
$$;

-- CALL scrub_email_batch('users', 'email');
```

## Explicação Detalhada

* **`CREATE OR REPLACE PROCEDURE scrub_email_batch(_tbl REGCLASS, _col VARCHAR(255)) ...`**:
    * Cria ou substitui uma procedure chamada `scrub_email_batch`.
    * A procedure recebe dois argumentos:
        * `_tbl`: O nome da tabela (do tipo `REGCLASS`).
        * `_col`: O nome da coluna de e-mail (do tipo `VARCHAR(255)`).
    * `LANGUAGE plpgsql` especifica que a procedure é escrita em PL/pgSQL.
* **`DECLARE ... BEGIN ... END;`**: Define o bloco de código da procedure.
* **`batch_size INT := 50;`**: Declara uma variável para o tamanho do lote, inicializando-a com 50.
* **`EXECUTE FORMAT('SELECT MAX(id), MIN(id) FROM %s', _tbl) INTO max_id, min_id;`**: Recupera os valores máximo e mínimo da coluna `id` da tabela especificada.
* **`RAISE INFO 'table=% column=% max_id=% min_id=%', _tbl, _col, max_id, min_id;`**: Exibe informações sobre a tabela, coluna e intervalo de IDs.
* **`FOR j IN min_id..max_id BY batch_size LOOP ... END LOOP;`**: Inicia um loop externo que itera sobre os registros da tabela em lotes.
* **`FOR k IN j..j + batch_size LOOP ... END LOOP;`**: Inicia um loop interno que itera sobre os registros em um lote.
* **`EXECUTE FORMAT('SELECT %s FROM %s WHERE id = %s', _col, _tbl, k) INTO orig_email;`**: Recupera o endereço de e-mail original do registro atual.
* **`CONTINUE WHEN orig_email IS NULL;`**: Pula a iteração atual se o endereço de e-mail original for nulo.
* **`RAISE INFO 'orig % ', orig_email;`**: Exibe o endereço de e-mail original.
* **`EXECUTE FORMAT('UPDATE %s SET %s = %s WHERE id = %s', _tbl, _col, QUOTE_LITERAL('xyz@example.com'), k);`**: Atualiza o registro atual com o endereço de e-mail limpo (atualmente um valor estático).
* **`RAISE INFO 'committing batch from % to % at %', j, j + batch_size, NOW();`**: Exibe informações sobre o lote que está sendo confirmado.
* **`COMMIT;`**: Confirma as alterações do lote.
* **`CALL scrub_email_batch('users', 'email');`**: Exemplo de como chamar a procedure.

## Considerações

* A procedure itera sobre os registros da tabela em lotes para evitar problemas de memória com tabelas grandes.
* Atualmente, a procedure substitui todos os endereços de e-mail por um valor estático (`xyz@example.com`). Você pode modificar a procedure para usar uma função PL/pgSQL personalizada para limpar os endereços de e-mail.
* A procedure usa `QUOTE_LITERAL()` para garantir que o valor do endereço de e-mail seja tratado como uma string literal na instrução `UPDATE`.
* A procedure assume que a tabela possui uma coluna `id` do tipo `BIGINT`. Se a sua tabela usar uma coluna de ID diferente, você precisará modificar a procedure.
* A procedure usa `COMMIT` dentro do loop externo para confirmar as alterações de cada lote. Isso pode ser útil para tabelas grandes, mas pode afetar o desempenho.
* A procedure exibe informações de depuração usando `RAISE INFO`. Você pode remover ou modificar essas instruções conforme necessário.
* A procedure não valida se o email inserido é um email válido.
