CREATE OR REPLACE PROCEDURE DOCKER_USER.SCHEMA_IMPORT (schemaname IN VARCHAR2)
IS
    h1 NUMBER; -- data pump job handle
    job_state VARCHAR2 (30);
    status ku$_Status; -- data pump status
    job_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT (job_not_exist, -31626);
    upper_schemaname VARCHAR2(64);
BEGIN
    upper_schemaname := UPPER(schemaname);
    
    BEGIN
        EXECUTE IMMEDIATE 'drop user "' || upper_schemaname || '" cascade';
    EXCEPTION 
        WHEN OTHERS 
        THEN dbms_output.put_line(SQLCODE);
    END; 

    EXECUTE IMMEDIATE 'create user "' || upper_schemaname || '" identified by "' || upper_schemaname || '"';
    EXECUTE IMMEDIATE 'grant dba to "' || upper_schemaname || '"';
    EXECUTE IMMEDIATE 'grant datapump_imp_full_database to "' || upper_schemaname || '"';
    EXECUTE IMMEDIATE 'grant read,write on directory DATA_PUMP_DIR to "' || upper_schemaname || '"';

    h1 := DBMS_DATAPUMP.open (operation => 'IMPORT', job_mode => 'SCHEMA', job_name => NULL);

    DBMS_DATAPUMP.set_parameter (h1, 'TABLE_EXISTS_ACTION', 'TRUNCATE');
    DBMS_DATAPUMP.add_file (h1, upper_schemaname || '_DB_BACKUP.DMP', 'DATA_PUMP_DIR');
    DBMS_DATAPUMP.add_file (h1, upper_schemaname || '_implog.log', 'DATA_PUMP_DIR', NULL, DBMS_DATAPUMP.KU$_FILE_TYPE_LOG_FILE);
    DBMS_DATAPUMP.METADATA_FILTER(h1, 'EXCLUDE_PATH_EXPR', 'IN (''STATISTICS'')');
    DBMS_DATAPUMP.start_job (h1);
 
    job_state := 'UNDEFINED';

    BEGIN
        WHILE (job_state != 'COMPLETED') AND (job_state != 'STOPPED') AND (job_state != 'COMPLETING')
        LOOP
            status := DBMS_DATAPUMP.get_status (handle => h1,
                            mask => DBMS_DATAPUMP.ku$_status_job_error
                            + DBMS_DATAPUMP.ku$_status_job_status
                            + DBMS_DATAPUMP.ku$_status_wip,
                            timeout => -1);

            job_state := status.job_status.state;

            DBMS_LOCK.sleep (10);
        END LOOP;
    EXCEPTION
    WHEN job_not_exist
    THEN
        DBMS_OUTPUT.put_line ('job finished');
    END;

    COMMIT;
END;
/