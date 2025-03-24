# Habilitar Acesso Remoto ao PostgreSQL

## Descrição

Este script demonstra os passos necessários para habilitar o acesso remoto a um servidor PostgreSQL. Ele envolve a configuração do arquivo `postgresql.conf` para permitir conexões de qualquer endereço IP e a modificação do arquivo `pg_hba.conf` para definir as regras de autenticação.

## Passos

1.  **Editar o arquivo `postgresql.conf`:**

    ```bash
    vim /var/lib/psql/13/data/postgresql.conf
    ```

    * Localize a linha `listen_addresses` e altere seu valor para `'*'`. Isso permite que o PostgreSQL escute conexões de todos os endereços IP disponíveis.

    ```
    listen_addresses = '*'
    ```

2.  **Editar o arquivo `pg_hba.conf`:**

    ```bash
    sudo vim /var/lib/pgsql/12/data/pg_hba.conf
    ```

    * Adicione as seguintes linhas ao arquivo para permitir conexões de qualquer endereço IP e de uma sub-rede confiável:

    ```
    # Accept from anywhere
    host all all 0.0.0.0/0 md5

    # Accept from trusted subnet
    host all all 192.168.0.0/24 md5
    ```

    * `host all all 0.0.0.0/0 md5`: Permite conexões de qualquer endereço IP para qualquer banco de dados e usuário, usando autenticação MD5. **Atenção:** Isso pode ser um risco de segurança em ambientes de produção. Recomenda-se restringir o acesso a endereços IP específicos ou sub-redes confiáveis.
    * `host all all 192.168.0.0/24 md5`: Permite conexões da sub-rede 192.168.0.0/24 para qualquer banco de dados e usuário, usando autenticação MD5.

3.  **Reiniciar o serviço PostgreSQL:**

    ```bash
    sudo systemctl restart postgresql-13
    ```

4.  **Recarregar a configuração do PostgreSQL:**

    ```bash
    psql -U postgres
    postgres=> select pg_reload_conf();
    ```

    * Isso garante que as alterações nos arquivos de configuração sejam aplicadas.

## Explicação Detalhada

* `postgresql.conf`: Este arquivo contém as configurações principais do servidor PostgreSQL, incluindo o endereço IP em que o servidor escuta as conexões.
* `pg_hba.conf`: Este arquivo define as regras de autenticação para conexões de clientes. Ele especifica quais usuários podem se conectar a quais bancos de dados e como a autenticação é realizada.
* `0.0.0.0/0`: Representa qualquer endereço IP.
* `192.168.0.0/24`: Representa a sub-rede 192.168.0.0 com máscara de sub-rede 24 bits.
* `md5`: Especifica o método de autenticação MD5.

## Considerações de Segurança

* Permitir conexões de qualquer endereço IP (`0.0.0.0/0`) pode ser um risco de segurança. Recomenda-se restringir o acesso a endereços IP específicos ou sub-redes confiáveis.
* Use autenticação forte (por exemplo, certificados SSL) em ambientes de produção.
* Revise e ajuste as regras de acesso no arquivo `pg_hba.conf` de acordo com os requisitos de segurança do seu ambiente.
* A versão do postgresql nos arquivos de configuração é diferente, atente-se a versão do postgresql que está utilizando.

## Exemplos de Uso

Este script pode ser usado para habilitar o acesso remoto a um servidor PostgreSQL para permitir que aplicativos ou usuários se conectem ao banco de dados de outras máquinas.
