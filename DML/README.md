# Repositório DML - Scripts PostgreSQL para Análise e Monitoramento

Este repositório contém scripts SQL para PostgreSQL, focados em análise de desempenho, monitoramento e diagnóstico de problemas em bancos de dados. Cada script foi renomeado para um nome descritivo e convertido para Markdown (.md) para facilitar a leitura e documentação.

## Lista de Scripts e Descrições

1.  **AcessoRemoto.md**
    * Detalhes sobre como configurar e gerenciar acesso remoto ao PostgreSQL.

2.  **DatabaseSize.md**
    * Scripts para verificar o tamanho total do banco de dados.

3.  **QueryPerformance.md**
    * Análise de desempenho de consultas, identificando queries lentas e ineficientes.

4.  **Running5minutes.md**
    * Lista queries em execução por mais de 5 minutos, auxiliando na identificação de problemas de desempenho.

5.  **active_autovacuums.md**
    * Monitora processos de autovacuum ativos, ajudando a entender o estado de manutenção do banco.

6.  **amanho_indices_e_estatisticas.md**
    * Detalhes sobre o tamanho dos índices e estatísticas de uso.

7.  **analise_autovacuum_tabelas.md**
    * Análise das configurações de autovacuum e estado das tabelas.

8.  **analise_autovacuum_vacuum_tabelas.md**
    * Análise das configurações de autovacuum (VACUUM) e estado das tabelas.

9.  **atividades_execucao.md**
    * Lista atividades em execução no PostgreSQL, excluindo o processo atual.

10. **autovaccum_conf.md**
    * Verifica e exibe parâmetros de configuração do autovacuum.

11. **bloat_tabelas_indices.md**
    * Identifica tabelas e índices com excesso de espaço não utilizado (bloat).

12. **bloqueios_tabelas.md**
    * Lista bloqueios em tabelas, auxiliando na identificação de problemas de concorrência.

13. **bloqueios_tabelas_e_cancelar_processo.md**
    * Scripts para listar bloqueios e cancelar processos que estão segurando bloqueios.

14. **chaves_estrangeiras_sem_indices.md**
    * Identifica chaves estrangeiras sem índices associados.

15. **estatisticas_tabelas_public.md**
    * Estatísticas de tabelas no esquema público, incluindo tamanho e número de índices.

16. **fragmentacao_indices_btree.md**
    * Análise de fragmentação de índices B-tree.

17. **index_hit_rate.md**
    * Calcula a taxa de acertos de índices.

18. **indices_duplicados.md**
    * Identifica índices duplicados.

19. **indices_faltantes.md**
    * Sugere índices faltantes com base em consultas.

20. **indices_pouco_utilizados.md**
    * Identifica índices pouco utilizados.

21. **maiores_tabelas.md**
    * Lista as maiores tabelas do banco de dados.

22. **processos_bloqueados_postgres.md**
    * Lista processos bloqueados no PostgreSQL.

23. **tamanho_tabelas_toast.md**
    * Detalha o tamanho das tabelas TOAST.

24. **tamanho_tablespace.md**
    * Verifica o tamanho dos tablespaces.

25. **taxa_acertos_blocos_heap.md**
    * Calcula a taxa de acertos de blocos de heap.

26. **triggers_tabelas.md**
    * Lista triggers definidos em tabelas de usuário.

27. **uso_cache_buffer_tabelas.md**
    * Analisa o uso do cache de buffer para tabelas.

28. **utilizacao_indices.md**
    * Analisa a utilização de índices em tabelas.

29. **verificar_status_postgresql.md**
    * Comandos úteis para verificar o status do PostgreSQL.

## Uso

Cada arquivo .md contém a query SQL e uma descrição detalhada de sua funcionalidade, além de exemplos de uso e considerações importantes.

## Contribuição

Contribuições são bem-vindas! Se você tiver scripts úteis ou melhorias para os existentes, sinta-se à vontade para criar um pull request.
