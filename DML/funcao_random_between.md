# Função PL/pgSQL para Gerar Números Aleatórios em um Intervalo

## Descrição

Esta função PL/pgSQL chamada `random_between` gera um número inteiro aleatório dentro de um intervalo especificado, incluindo os limites inferior e superior.

## Função

```sql
CREATE OR REPLACE FUNCTION random_between(low INT, high INT)
RETURNS INT AS $$
BEGIN
    RETURN FLOOR(RANDOM() * (high - low + 1) + low);
END;
$$ LANGUAGE 'plpgsql' STRICT;
```

## Explicação Detalhada

* **`CREATE OR REPLACE FUNCTION random_between(low INT, high INT) RETURNS INT AS $$ ... $$ LANGUAGE 'plpgsql' STRICT;`**:
    * Cria ou substitui uma função chamada `random_between`.
    * A função recebe dois argumentos inteiros, `low` e `high`, que representam os limites inferior e superior do intervalo.
    * A função retorna um valor inteiro.
    * `LANGUAGE 'plpgsql'` especifica que a função é escrita em PL/pgSQL.
    * `STRICT` especifica que a função sempre retorna NULL quando qualquer um dos seus argumentos é NULL.
* **`BEGIN ... END;`**: Define o bloco de código da função.
* **`RETURN FLOOR(RANDOM() * (high - low + 1) + low);`**:
    * `RANDOM()`: Gera um número decimal aleatório entre 0 e 1 (exclusivo).
    * `(high - low + 1)`: Calcula o tamanho do intervalo (incluindo os limites).
    * `RANDOM() * (high - low + 1)`: Gera um número decimal aleatório dentro do intervalo.
    * `RANDOM() * (high - low + 1) + low`: Desloca o número aleatório para o intervalo correto.
    * `FLOOR(...)`: Arredonda o número decimal para o menor inteiro mais próximo.
* A função então retorna o inteiro aleatório gerado.

## Exemplos de Uso

1.  Para gerar um número aleatório entre 1 e 10:

    ```sql
    SELECT random_between(1, 10);
    ```

2.  Para gerar um número aleatório entre -5 e 5:

    ```sql
    SELECT random_between(-5, 5);
    ```

## Considerações

* A função `RANDOM()` gera números pseudoaleatórios.
* A função `FLOOR()` garante que o resultado seja um número inteiro.
* A função `STRICT` lida com casos em que os argumentos são nulos.
* Certifique-se que o valor de high seja maior que o valor de low.
* Essa função é muito útil para gerar dados de teste.
