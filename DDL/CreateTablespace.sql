-- Com owner que estiver logado
CREATE TABLESPACE ts_primary LOCATION 'c:\pgdata\primary';

-- Com outro owner
CREATE TABLESPACE indexspace OWNER genevieve LOCATION '/data/indexes';
