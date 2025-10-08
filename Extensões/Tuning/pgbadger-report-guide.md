# Instalação e Configuração do pgBadger (v13.1)

Este guia detalha o processo de instalação da ferramenta de análise de logs **pgBadger** a partir do código-fonte e a configuração básica do **PostgreSQL** para geração de logs otimizados para a análise.

## 1\. Instalação de Dependências

Instale as dependências de Perl necessárias para a compilação do `pgBadger`.

```bash
sudo dnf install perl perl-Text-CSV_XS perl-UNIVERSAL-isa
```

## 2\. Download do Código-Fonte

Baixe a versão 13.1 do código-fonte do `pgBadger` do repositório oficial.

```bash
wget https://github.com/darold/pgbadger/archive/refs/tags/v13.1.tar.gz
```

## 3\. Extração e Navegação

Extraia o arquivo baixado e navegue para o diretório do projeto.

```bash
tar -xvf v13.1.tar.gz
cd pgbadger-13.1
```

## 4\. Compilação e Instalação

Compile e instale o `pgBadger` no seu sistema.

```bash
perl Makefile.PL
make
sudo make install
```

## 5\. Verificação da Instalação

Verifique se o `pgBadger` foi instalado corretamente e exibe sua versão.

```bash
pgbadger --version
```

-----

# Configuração do PostgreSQL para Análise de Logs

Para que o `pgBadger` possa gerar relatórios detalhados, o PostgreSQL deve ser configurado para gerar logs com um formato específico e capturar informações importantes.

## 1\. Edição do `postgresql.conf`

Edite o arquivo de configuração principal do PostgreSQL. O caminho pode variar, mas um local comum é: `/var/lib/pgsql/data/postgresql.conf`.

```bash
sudo nano /var/lib/pgsql/data/postgresql.conf
```

## 2\. Adicionar/Modificar Parâmetros de Log

Adicione ou modifique as seguintes linhas no arquivo `postgresql.conf` para otimizar a geração de logs.

```conf
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_statement = 'all'
log_duration = on
log_min_duration_statement = 0
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 0
```

> **Atenção:** Após salvar as alterações no `postgresql.conf`, lembre-se de **reiniciar o serviço do PostgreSQL** para que as novas configurações entrem em vigor.

-----

# Geração do Relatório

## 1\. Estressar o Ambiente (Opcional)

Execute uma ferramenta de benchmark, como o `pgbench`, para gerar carga e criar um volume maior de logs com **insights** relevantes para o relatório.

```bash
pgbench -c 50 -j 10 -T 300 -M prepared benchdbp
```

## 2\. Execução do pgBadger

Execute o `pgBadger`, especificando o formato dos logs (`-f stderr`), o arquivo de saída do relatório (`-o`), e os arquivos de log do PostgreSQL a serem analisados.

```bash
pgbadger -f stderr -o /pg01/pgsql17_data/reports/report_02.html /pg01/pgsql17_data/log/postgresql-*.log
```

O relatório estará disponível no arquivo no drive https://drive.google.com/file/d/1wBEAqbljeujAJzQYvoetgg2XTyLwJhAG/view?usp=drive_link
Faça download e abra no navegador.
