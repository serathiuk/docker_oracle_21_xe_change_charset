alter session set "_ORACLE_SCRIPT"=true;
alter system set nls_length_semantics=CHAR scope=both;
shutdown;
startup restrict;
alter database character set INTERNAL_USE WE8MSWIN1252;
shutdown;
startup;
execute dbms_metadata_util.load_stylesheets;

alter session set "_ORACLE_SCRIPT"=true;
create user docker_user identified by docker_user;
grant DBA to docker_user;
GRANT execute ON DBMS_LOCK TO docker_user;
grant datapump_imp_full_database to docker_user;
grant read,write on directory DATA_PUMP_DIR to docker_user;
GRANT ALL PRIVILEGES TO docker_user;