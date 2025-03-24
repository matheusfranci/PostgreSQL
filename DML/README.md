# Repositório de Scripts SQL para PostgreSQL (dml)

Este repositório contém uma coleção de scripts SQL úteis para monitoramento, análise e otimização de bancos de dados PostgreSQL. Os scripts abrangem diversas áreas, incluindo desempenho de consultas, gerenciamento de índices, análise de bloat, monitoramento de bloqueios, estatísticas de tabelas e muito mais.

## Organização dos Scripts

Os scripts estão organizados em arquivos Markdown (.md) para facilitar a leitura e o uso. Cada arquivo contém:

* Uma descrição detalhada do script.
* A query SQL.
* Explicações sobre como usar o script.
* Considerações importantes.

## Lista de Scripts

A seguir, uma lista dos scripts disponíveis e suas descrições:

* **AcessoRemoto.md**: Configurações para acesso remoto ao PostgreSQL.
* **DatabaseSize.md**: Informações sobre o tamanho do banco de dados.
* **QueryPerformance.md**: Análise do desempenho de consultas.
* **Running5minutes.md**: Consultas em execução nos últimos 5 minutos.
* **active_autovacuums.md**: Autovacuums ativos no momento.
* **ajuste_parametros_postgres.md**: Ajuste de parâmetros do PostgreSQL.
* **analise_autovacuum_tabelas.md**: Análise de estatísticas do autovacuum.
* **analise_autovacuum_vacuum_tabelas.md**: Análise detalhada do autovacuum e vacuum.
* **approximate_count.md**: Contagem aproximada de linhas em tabelas grandes.
* **atividades_execucao.md**: Atividades em execução no banco de dados.
* **autovaccum_conf.md**: Configurações do autovacuum.
* **b3_table_pgstattuple.md**: Informações detalhadas da tabela usando pgstattuple.
* **b4_btree_pgstattuple.md**: Informações detalhadas do índice B-tree usando pgstattuple.
* **b5_tables_no_stats.md**: Tabelas sem estatísticas atualizadas.
* **bloat_indices_btree.md**: Bloat em índices B-tree.
* **bloat_tabelas_indices.md**: Bloat em tabelas e índices.
* **bloqueios_detalhes_timeout.md**: Detalhes de bloqueios e timeouts.
* **bloqueios_tabelas.md**: Bloqueios em tabelas.
* **bloqueios_tabelas_e_cancelar_processo.md**: Bloqueios em tabelas e cancelamento de processos.
* **cache_hit_rate.md**: Taxa de acerto do cache.
* **calculo_bloat_indices_btree.md**: Cálculo detalhado do bloat em índices B-tree.
* **calculo_bloat_tabelas.md**: Cálculo detalhado do bloat em tabelas.
* **calculo_bloat_tabelas_02.md**: Cálculo alternativo do bloat em tabelas.
* **chaves_estrangeiras_sem_indices.md**: Chaves estrangeiras sem índices.
* **collations.md**: Listagem das collations do banco de dados.
* **conexoes_ociosas_em_transacao.md**: Conexões ociosas em transação.
* **constraint_definition_ddl.md**: Definições de constraints (DDL).
* **consultas_longas_duracao.md**: Consultas de longa duração.
* **consultas_mais_lentas.md**: Consultas mais lentas.
* **contagem_linhas_tabelas_padrao.md**: Contagem de linhas em tabelas padrão.
* **create_index_create_statement.md**: Geração de instruções CREATE INDEX.
* **detalhes_colunas_tabela.md**: Detalhes das colunas de uma tabela.
* **estatisticas_bancos_dados.md**: Estatísticas dos bancos de dados.
* **estatisticas_consultas_pg_stat_statements.md**: Estatísticas de consultas usando pg_stat_statements.
* **estatisticas_tabelas_public.md**: Estatísticas das tabelas no esquema public.
* **estatisticas_valores_nulos.md**: Estatísticas de valores nulos em colunas.
* **estimar_desperdicio_alinhamento.md**: Estimativa do desperdício de espaço devido ao alinhamento.
* **find_missing_indexes.md**: Índices faltantes.
* **find_replica_identity.md**: Identificação de replica identity.
* **fragmentacao_indices_btree.md**: Fragmentação de índices B-tree.
* **funcao_random_between.md**: Função para gerar números aleatórios entre um intervalo.
* **funcao_scrub_email.md**: Função para limpar endereços de e-mail.
* **generate_series.md**: Uso da função generate_series.
* **gerenciamento_xid.md**: Gerenciamento de XIDs (Transaction IDs).
* **i3_non_indexed_fks.md**: Chaves estrangeiras não indexadas.
* **i4_invalid_indexes.md**: Índices inválidos.
* **i5_indexes_migration.md**: Índices para migração.
* **identificar_deadlocks_detalhes.md**: Identificação detalhada de deadlocks.
* **idle_sessions_count.md**: Contagem de sessões ociosas.
* **index_hit_rate.md**: Taxa de acerto de índices.
* **indices_candidatos_remocao_otimizacao.md**: Índices candidatos à remoção ou otimização.
* **indices_candidatos_remocao_otimizacao_v2.md**: Índices candidatos à remoção ou otimização (versão alternativa).
* **indices_duplicados.md**: Índices duplicados.
* **indices_faltantes.md**: Índices faltantes.
* **indices_parciais_candidatos.md**: Índices parciais candidatos.
* **indices_pouco_utilizados.md**: Índices pouco utilizados.
* **indices_redundantes_com_fk.md**: Índices redundantes com chaves estrangeiras.
* **informacoes_bancos_dados.md**: Informações sobre os bancos de dados.
* **insert_only_pg_stat_user_tables.md**: Tabelas com apenas inserções.
* **list_partitioned_tables.md**: Listagem de tabelas particionadas.
* **list_schemas.md**: Listagem de schemas.
* **listar_enums.md**: Listagem de enums.
* **listar_sequencias.md**: Listagem de sequências.
* **listar_views_esquema_atual.md**: Listagem de views no esquema atual.
* **maiores_tabelas.md**: Maiores tabelas do banco de dados.
* **processos_bloqueados_postgres.md**: Processos bloqueados no PostgreSQL.
* **recuperar_chaves_estrangeiras.md**: Recuperação de chaves estrangeiras.
* **relatorio_estatisticas_consultas_pg_stat_statements.md**: Relatório de estatísticas de consultas usando pg_stat_statements.
* **resumo_atividades_postgres.md**: Resumo das atividades no PostgreSQL.
* **scrub_email_batch.md**: Limpeza de emails em lote.
* **status_banco_dados.md**: Status do banco de dados.
* **status_vacuum_tabelas.md**: Status do vacuum em tabelas.
* **tabelas_candidatas_vacuum.md**: Tabelas candidatas a vacuum.
* **tabelas_indices_detalhes.md**: Detalhes de tabelas e índices.
* **tabelas_particionadas_tamanhos.md**: Tamanhos de tabelas particionadas.
* **tabelas_sem_pk.md**: Tabelas sem chaves primárias.
* **tamanho_detalhado_tabelas.md**: Tamanho detalhado das tabelas.
* **tamanho_indices_e_estatisticas.md**: Tamanho dos índices e estatísticas.
* **tamanho_tabelas_detalhado.md**: Tamanho detalhado das tabelas.
* **tamanho_tabelas_toast.md**: Tamanho das tabelas TOAST.
* **tamanho_tablespace.md**: Tamanho das tablespaces.
* **tamanho_total_relacao.md**: Tamanho total das relações (tabelas e índices).
* **taxa_acertos_blocos_heap.md**: Taxa de acertos de blocos de heap no cache.
* **top_updated_tables.md**: Tabelas com mais atualizações.
* **triggers_tabelas.md**: Triggers em tabelas.
* **ultimos_autovacuums.md**: Últimos autovacuums executados.
* **uso_cache_buffer_tabelas.md**: Uso do cache de buffer por tabelas.
* **uso_indices_tabelas.md**: Uso de índices por tabelas.
* **uso_modificacoes_tabelas.md**: Uso de modificações em tabelas.
* **utilizacao_indices.md**: Utilização de índices.
* **verificar_status_postgresql.md**: Verificação do status do PostgreSQL.
* **verificar_versoes_extensoes.md**: Verificação das versões de extensões.
* **waiting_queries.sql**: Consultas em espera.

## Como Usar

1.  Clone este repositório para sua máquina local.
2.  Conecte-se ao seu banco de dados PostgreSQL usando um cliente SQL (por exemplo, `psql`, pgAdmin).
3.  Execute os scripts SQL desejados.

## Contribuição

Contribuições são bem-vindas! Se você tiver scripts SQL úteis que gostaria de compartilhar, sinta-se à vontade para enviar um pull request.

## Licença

Este repositório está sob a licença [MIT](LICENSE).
