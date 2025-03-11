## Administrando PostgreSQL em um Contêiner Docker

Este guia detalha os passos para interagir com um contêiner Docker que executa o PostgreSQL, incluindo listagem de contêineres, acesso ao shell e ao psql, inspeção de contêineres e acesso com usuário e senha.

### 1. Listando Contêineres

Para verificar os contêineres Docker em execução, utilize o seguinte comando:

```bash
docker ps
```

A saída exibirá uma tabela com informações sobre os contêineres, como:

```
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                     NAMES
xxxxxxxxxxxx        docker_worker_1     "bash -c 'airflow ..."   2 months ago        Up 2 months         xxxx/tcp                  airflow_worker_1
xxxxxxxxxxxx        docker_worker_2     "bash -c 'airflow ..."   2 months ago        Up 2 months         xxxx/tcp                  airflow_worker_2
xxxxxxxxxxxx        docker_scheduler    "bash -c 'airflow ..."   2 months ago        Up 2 months         xxxx/tcp                  airflow_scheduler
xxxxxxxxxxxx        docker_webserver    "bash -c 'airflow ..."   2 months ago        Up 2 months (healthy) 0.0.0.0:xxxx->xxxx/tcp     airflow_webserver
xxxxxxxxxxxx        redis:5.0.5         "docker-entrypoint..."   2 months ago        Up 2 months         xxxx/tcp                  airflow_redis
xxxxxxxxxxxx        postgres:9          "docker-entrypoint..."   2 months ago        Up 2 months         0.0.0.0:xxxx->xxxx/tcp     airflow_postgres
```

Observe o nome do contêiner PostgreSQL (neste caso, `airflow_postgres`).

### 2. Acessando o Shell do Contêiner

Para entrar no shell do contêiner PostgreSQL, utilize o comando `docker exec`:

```bash
docker exec -it airflow_postgres bash
```

Substitua `airflow_postgres` pelo nome do seu contêiner.

Para acessar o shell de qualquer outro contêiner, use:

```bash
docker exec -it nomedocontainer bash
```

### 3. Acessando o psql

Dentro do shell do contêiner, você pode acessar o psql com o usuário padrão `postgres`:

```bash
docker exec -it airflow_postgres psql -U postgres
```

Ou, caso queira acessar o psql diretamente utilizando o host e porta, execute:

```bash
psql -h xxxxxxxxxx -p 5432 -U postgres
```

### 4. Verificando Informações do Contêiner

Para obter informações detalhadas sobre um contêiner, utilize `docker inspect`:

```bash
docker inspect xxxxxxxxxxx
```

Ou, usando o ID do contêiner:

```bash
docker inspect idcontainer
```

### 5. Verificando Variáveis de Ambiente

Ao inspecionar o contêiner, procure pelas variáveis de ambiente que definem o usuário e a senha do PostgreSQL:

```
"POSTGRES_USER=youruser",
"POSTGRES_PASSWORD=yourpassword",
```

### 6. Acessando o psql com Usuário e Senha

Se você precisar acessar o psql com um usuário e senha específicos, siga estes passos:

1.  Entre no shell do contêiner:

    ```bash
    docker exec -it airflow_postgres bash
    ```

2.  Mude para o usuário `postgres` (ou o usuário definido em `POSTGRES_USER`):

    ```bash
    su postgres
    ```

3.  Acesse o psql com o usuário e senha (se necessário, o psql solicitará a senha):

    ```bash
    psql -U myuser
    ```
