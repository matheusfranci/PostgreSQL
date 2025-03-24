# Função PL/pgSQL para Limpar Endereços de E-mail

## Descrição

Esta função PL/pgSQL chamada `scrub_email` recebe um endereço de e-mail como entrada e retorna um novo endereço de e-mail onde a parte local (antes do `@`) é substituída por uma string aleatória gerada por MD5. A função garante que a string aleatória tenha pelo menos 5 caracteres para evitar colisões.

## Função

```sql
CREATE OR REPLACE FUNCTION scrub_email(email_address VARCHAR(255)) RETURNS VARCHAR(255) AS $$
BEGIN
    RETURN
        -- take random MD5 text that is the same
        -- length as the first part of the email address
        -- EXCEPT when it's less than 5 chars, since we might
        -- have a collision. In that case use 5: greatest(length,6)
        CONCAT(
            SUBSTR(MD5(RANDOM()::TEXT), 0, GREATEST(LENGTH(SPLIT_PART(email_address, '@', 1)) + 1, 6)),
            '@',
            SPLIT_PART(email_address, '@', 2)
        );
END;
$$ LANGUAGE plpgsql;
```

## Explicação Detalhada

* **`CREATE OR REPLACE FUNCTION scrub_email(email_address VARCHAR(255)) RETURNS VARCHAR(255) AS $$ ... $$ LANGUAGE plpgsql;`**:
    * Cria ou substitui uma função chamada `scrub_email`.
    * A função recebe um argumento `email_address` do tipo `VARCHAR(255)` (endereço de e-mail).
    * A função retorna um valor do tipo `VARCHAR(255)` (endereço de e-mail limpo).
    * `LANGUAGE plpgsql` especifica que a função é escrita em PL/pgSQL.
* **`BEGIN ... END;`**: Define o bloco de código da função.
* **`SPLIT_PART(email_address, '@', 1)`**: Extrai a parte local do endereço de e-mail (antes do `@`).
* **`LENGTH(...)`**: Calcula o comprimento da parte local do endereço de e-mail.
* **`GREATEST(..., 6)`**: Garante que o comprimento da string aleatória seja pelo menos 6 caracteres.
* **`RANDOM()::TEXT`**: Gera um número aleatório e o converte em texto.
* **`MD5(...)`**: Calcula o hash MD5 da string aleatória.
* **`SUBSTR(..., 0, ...)`**: Extrai uma substring do hash MD5 com o comprimento calculado.
* **`SPLIT_PART(email_address, '@', 2)`**: Extrai o domínio do endereço de e-mail (após o `@`).
* **`CONCAT(..., '@', ...)`**: Concatena a string aleatória, o caractere `@` e o domínio para formar o novo endereço de e-mail.
* **`RETURN ...`**: Retorna o endereço de e-mail limpo.

## Exemplos de Uso

```sql
SELECT scrub_email('[email address removed]');
-- Resultado: uma string como '[email address removed]'
SELECT scrub_email('[email address removed]');
-- Resultado: uma string como '[email address removed]'
```

## Considerações

* A função usa `MD5` para gerar uma string aleatória, que não é criptograficamente segura. Para fins de segurança, considere usar uma função de hash mais forte.
* A função garante que a string aleatória tenha pelo menos 6 caracteres para evitar colisões, mas ainda há uma pequena chance de colisões se muitos endereços de e-mail forem limpos.
* A função preserva o domínio do endereço de e-mail.
* Esta função é útil para anonimizar endereços de e-mail em dados de teste ou ambientes de desenvolvimento.
* O uso da função random() torna o resultado não determinístico.
* A função não valida se o email inserido é um email válido.
