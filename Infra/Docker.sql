-- Administrando postgresql em docker container

--Listando containers
docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                  PORTS                    NAMES
xxxxxxxxxxxx        docker_worker_1     "bash -c 'airflow ..."   2 months ago        Up 2 months             xxxx/tcp                 airflow_worker_1
xxxxxxxxxxxx        docker_worker_2     "bash -c 'airflow ..."   2 months ago        Up 2 months             xxxx/tcp                 airflow_worker_2
xxxxxxxxxxxx        docker_scheduler    "bash -c 'airflow ..."   2 months ago        Up 2 months             xxxx/tcp                 airflow_scheduler
xxxxxxxxxxxx        docker_webserver    "bash -c 'airflow ..."   2 months ago        Up 2 months (healthy)   0.0.0.0:xxxx->xxxx/tcp   airflow_webserver
xxxxxxxxxxxx        redis:5.0.5         "docker-entrypoint..."   2 months ago        Up 2 months             xxxx/tcp                 airflow_redis
xxxxxxxxxxxx        postgres:9          "docker-entrypoint..."   2 months ago        Up 2 months             0.0.0.0:xxxx->xxxx/tcp   airflow_postgres

-- Entrando no container
docker exec -it airflow_postgres bash
docker exec -it nomedocontainer bash


-- Entrando no psql
docker exec -it airflow_postgres psql -U postgres

psql -h xxxxxxxxxx -p 5432 -U postgres

-- Verificando informações de um container
docker inspect xxxxxxxxxxx
docker inspect idcontainer


-- Verifique as variáveis
"POSTGRES_USER=youruser",
"POSTGRES_PASSWORD=yourpassword",

-- Acesse o container e execute o psql com o usuário e senha
su postgres
psql -U myuser
