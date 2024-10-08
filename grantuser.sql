create tablespace "SBLDBDATA" datafile 'C:\ORACLE\ORADATA\SDB\SBLDBDATA01.DBF' size 500m AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED LOGGING EXTENT MANAGEMENT LOCAL SEGMENT SPACE MANAGEMENT AUTO;

create tablespace "SBLDBIDX" datafile 'C:\ORACLE\ORADATA\SDB\SBLDBIDX01.DBF' size 500m AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED LOGGING EXTENT MANAGEMENT LOCAL SEGMENT SPACE MANAGEMENT AUTO;

create  role sse_role;

create  role tblo_role;

grant create session to sse_role;

grant ALTER SESSION, CREATE CLUSTER, CREATE DATABASE LINK, CREATE INDEXTYPE,

  CREATE OPERATOR, CREATE PROCEDURE, CREATE SEQUENCE, CREATE SESSION,

  CREATE SYNONYM, CREATE TABLE, CREATE TRIGGER, CREATE TYPE, CREATE VIEW,

  CREATE DIMENSION, CREATE MATERIALIZED VIEW, QUERY REWRITE, ON COMMIT REFRESH

to tblo_role;

create user SIEBEL identified by siebel123;

create user SADMIN identified by sadmin123;

create  user LDAPUSER identified by ldapuser123;

create  user GUESTCST identified by guestcst123;

grant tblo_role to SIEBEL;

grant sse_role to SIEBEL;

alter user SIEBEL quota 0 on SYSTEM quota 0 on SYSAUX;

alter user SIEBEL default tablespace SBLDBDATA;

alter user SIEBEL temporary tablespace TEMP;

alter user SIEBEL quota unlimited on SBLDBDATA;

alter user SIEBEL quota unlimited on SBLDBIDX;

grant sse_role to SADMIN;

grant UNLIMITED tablespace TO SADMIN;

alter user SADMIN default tablespace SBLDBDATA;

alter user SADMIN temporary tablespace TEMP;

alter user SADMIN quota unlimited on SBLDBDATA;

alter user SADMIN quota unlimited on SBLDBIDX;

grant sse_role to LDAPUSER;

alter user LDAPUSER default tablespace SBLDBDATA;

alter user LDAPUSER temporary tablespace TEMP;

alter user LDAPUSER quota unlimited on SBLDBDATA;

grant sse_role to GUESTCST;

alter user GUESTCST default tablespace SBLDBDATA;

alter user GUESTCST temporary tablespace TEMP;