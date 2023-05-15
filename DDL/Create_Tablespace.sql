mkdir /consinco
chown postgres:postgres /consinco -R
chmod 700 /consinco -R

-- Criando tablespace
CREATE TABLESPACE data LOCATION '/consinco';

-- Criando banco para gravar dados na tablespace 
CREATE DATABASE ORION TABLESPACE data

-- Criando índice
CREATE UNIQUE INDEX unq_street ON public.addresses (street);

-- Dropando índice 
DROP INDEX unq_street;
