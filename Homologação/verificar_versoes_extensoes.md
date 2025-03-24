# Verificar Versões de Extensões Instaladas no PostgreSQL

## Descrição

Este script SQL compara as versões instaladas de extensões do PostgreSQL com as versões padrão disponíveis. Ele identifica extensões que estão desatualizadas (ou seja, a versão instalada é diferente da versão padrão).

## Query

```sql
SELECT
    ae.name,
    installed_version,
    default_version,
    CASE WHEN installed_version <> default_version THEN 'OLD' END AS is_old
FROM pg_extension e
JOIN pg_available_extensions ae ON extname = ae.name
ORDER BY ae.name;
```

## Explicação Detalhada

* **`pg_extension`**: Esta tabela do sistema contém informações sobre extensões instaladas no banco de dados.
* **`pg_available_extensions`**: Esta visão do sistema contém informações sobre extensões disponíveis para instalação.
* **`ae.name`**: O nome da extensão.
* **`installed_version`**: A versão instalada da extensão.
* **`default_version`**: A versão padrão disponível da extensão.
* **`CASE WHEN installed_version <> default_version THEN 'OLD' END AS is_old`**: Cria uma coluna `is_old` que indica se a versão instalada é diferente da versão padrão.
* **`JOIN pg_available_extensions ae ON extname = ae.name`**: Junta as tabelas `pg_extension` e `pg_available_extensions` com base no nome da extensão.
* **`ORDER BY ae.name`**: Ordena os resultados pelo nome da extensão.

## Exemplos de Uso

Este script pode ser usado para:

* Verificar se todas as extensões instaladas estão atualizadas.
* Identificar extensões que precisam ser atualizadas.
* Auxiliar na manutenção e atualização do banco de dados.

## Considerações

* Extensões desatualizadas podem ter problemas de segurança ou desempenho.
* Atualizar extensões para as versões mais recentes é uma prática recomendada.
* A atualização de uma extensão pode ser realizada com o comando `ALTER EXTENSION nome_extensao UPDATE;`.
* É importante verificar as notas de versão de cada extensão antes de atualizá-las.
* Caso a coluna is\_old esteja vazia, a extensão está atualizada.
