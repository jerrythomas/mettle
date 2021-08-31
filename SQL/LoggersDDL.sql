-- $Header LoggersDDL.sql 0.01 11-Dec-2007 Jerry
/*
 * File Name  : LoggersDDL.sql
 * Purpose    : Table definitions for tracking progress of data transfer processes.
 * Author     : Jerry Thomas
 * Version    : 0.01
 * Created On : 11-Dec-2007
 *
 * Features
 *   => Track progress of data transfer processes
 *   => Summary of the rows processed by stage
 *   => Timestamp when the process was initiated
 *   => Timestamp when the process completed
 *   => Actual duration the process ran for
 *   => Time for which
 *
 */
/*
 What are the programs that will need to track
 a) Scheduler           - executes individual processes (only 1 instance running at any point)
 b) Translate & Compile - Converts UI mapping to actual code
 c) Each Individual data transformation executable
      Executable Name can be common across projects/Environments, so executable name is not unique
       => i will need to create dummy mappings to refer to the controlling programs and refer to
       => the mapping data table
-- ETL-App will be a transient data set. this will need to be flushed out as and when connections are dropped.
-- a reference to the actual process_id may help in cleaning up any old connections etc
--
-- Logger Views
-- Process Status View
-- Performance_History view
-- Archive Tables
  Loggers

     Execution Log
      ID
      Map_ID
      process id -> to be used to kill
      Phase       [E]-> Src [V,T]->flow server [L][tgt] or [E] [LTV or VTL] ->tgt
      Start time
      End time
      Records
      Status   [ initiated/ processing/ successful/failure/killed]

     Performance Log
      ExecID
      Map_ID
      Component_ID
      Message/Task Description
      start time
      end time
      (TimeHH,MI,SS) ?
      records

     Error Log
      ExecID
      Map_ID
      Component_ID
      Error code
      Error Message
      Error file
      Trace File

  System Profilers
    Perf stats from the diff sources
*/

SET search_path TO logs,public;
drop view if exists core.runnable_v;

DROP TABLE IF EXISTS clients ;
DROP TABLE IF EXISTS errors  ;
DROP TABLE IF EXISTS activity;
DROP TABLE IF EXISTS stage   ;
DROP TABLE IF EXISTS process ;

DROP SEQUENCE IF EXISTS process_id_sq ;
DROP SEQUENCE IF EXISTS stage_id_sq   ;
DROP SEQUENCE IF EXISTS activity_id_sq;
DROP SEQUENCE IF EXISTS error_id_sq  ;
DROP SEQUENCE IF EXISTS client_id_sq ;

SET default_tablespace = cf_logs_dat;

CREATE SEQUENCE process_id_sq
     START WITH 1
   INCREMENT BY 1;

-- Every instantiated application is logged.
CREATE TABLE process
(
    id                              NUMERIC(10) PRIMARY KEY DEFAULT NEXTVAL('process_id_sq')
   ,task_id                         NUMERIC(10)    -- Reference to the executable object
   ,os_pid                          NUMERIC(10)    -- PID of the actual Unix process
   ,status                          VARCHAR(10)    -- status of the process (initiated, started, Processing, completed,terminated?)
   ,stage                           VARCHAR(15)    -- current stage (Extract,'E', Transform,'T', Validation 'V', Build Keys 'BK', Load 'L')
   ,rows_extracted                  NUMERIC(10)    --
   ,rows_loaded                     NUMERIC(10)    --
   ,rows_transformed                NUMERIC(10)    --
   ,rows_rejected                   NUMERIC(10)    --
   ,rows_with_dangling_keys         NUMERIC(10)    --
   ,scheduled_at                    TIMESTAMP
   ,initiated_at                    TIMESTAMP WITH TIME ZONE  DEFAULT NOW() -- Start TS
   ,completed_at                    TIMESTAMP WITH TIME ZONE      -- Completion TS
   ,wait_duration                   INTERVAL       -- Wait Time
   ,run_duration                    INTERVAL       -- Time Taken
   ,slicing_mode                    CHAR(10)    -- Time/Unique/Ref Key
   ,ts_lower_bound                  TIMESTAMP      --
   ,ts_upper_bound                  TIMESTAMP      --
   ,ns_lower_bound                  NUMERIC(10)    --
   ,ns_upper_bound                  NUMERIC(10)    --
   ,pattern_match                   VARCHAR(500)   -- file name
   ,reprocessed                     BOOLEAN        DEFAULT FALSE     -- Indicates if a terminated or error process was re-processed
   ,server                          VARCHAR(10)    -- Server name
   ,error_file                      VARCHAR(200)   -- can be ignored file name can follow a fixed format and a configurable path
   ,trace_file                      VARCHAR(200)   -- can be ignored as above
   ,original_process_id             NUMERIC(10)    -- For jobs that were reprocessed.
   ,user_id                         VARCHAR(20)    -- User who submitted the job (for manual execution)
   ,submitted_on                    TIMESTAMP WITH TIME ZONE -- TS
);

ALTER INDEX process_pkey SET TABLESPACE cf_logs_idx;

ALTER TABLE process
        ADD CONSTRAINT process_task_fk
               FOREIGN KEY (task_id)
            REFERENCES core.task (id);

CREATE INDEX process_task_fk
          ON process(task_id)
  TABLESPACE cf_logs_idx;

CREATE SEQUENCE stage_id_sq
     START WITH 1
   INCREMENT BY 1;

CREATE TABLE stage
(
    id                              NUMERIC(10) PRIMARY KEY DEFAULT NEXTVAL('stage_id_sq')
   ,process_id                      NUMERIC(10)
   ,kind                            VARCHAR(15)  -- Extract,'E', Transform,'T', Validation 'V', Build Keys 'BK', Load 'L', {non WH Maps may use other stages}
   ,rows_processed                  NUMERIC(10) --
   ,initiated_at                    TIMESTAMP WITH TIME ZONE  DEFAULT NOW()-- Actual start time (after the wait)
   ,completed_at                    TIMESTAMP WITH TIME ZONE  --
   ,duration                        INTERVAL
   ,wait_duration                   INTERVAL    -- Waiting Time
   ,wait_reason                     VARCHAR     -- Reason for the wait
   ,status                          VARCHAR(10)
);

ALTER INDEX stage_pkey SET TABLESPACE cf_logs_idx;
ALTER TABLE stage
        ADD CONSTRAINT stage_fkey
               FOREIGN KEY (process_id)
            REFERENCES process(id);

CREATE INDEX stage_fkey
          ON stage(process_id)
  TABLESPACE cf_logs_idx;

CREATE SEQUENCE activity_id_sq
     START WITH 1
   INCREMENT BY 1;

CREATE TABLE activity
(
    id                              NUMERIC(10) PRIMARY KEY DEFAULT NEXTVAL('activity_id_sq')
   ,stage_id                        NUMERIC(10)
   ,name                            VARCHAR(30)   -- Short name
   ,type_name                       VARCHAR(30)   -- SQL Type (I,D,U or other indicators if not SQL) can be the mapping component also
   ,description                     VARCHAR(255)  -- Description of the step
   ,execution_seq                   NUMERIC(10)   -- Sequence of execution
   ,path                            VARCHAR(20)   -- Identify the thread?
   ,status                          VARCHAR(10)   --
   ,log_level                       NUMERIC(2)    -- Logging Level
   ,executed_by                     VARCHAR(20)   -- DB Server / ETL Server
   ,initiated_at                    TIMESTAMP WITH TIME ZONE    --
   ,completed_at                    TIMESTAMP WITH TIME ZONE    --
   ,duration                        INTERVAL      --
   ,rows_processed                  NUMERIC(20)   --
);

ALTER INDEX activity_pkey SET TABLESPACE cf_logs_idx;
ALTER TABLE activity
        ADD CONSTRAINT activity_fkey
               FOREIGN KEY (stage_id)
            REFERENCES stage(id);

CREATE INDEX activity_fkey
          ON activity(stage_id)
  TABLESPACE cf_logs_idx;

CREATE SEQUENCE error_id_sq
     START WITH 1
   INCREMENT BY 1;

CREATE TABLE errors
(
    id                            NUMERIC(10) PRIMARY KEY DEFAULT NEXTVAL('error_id_sq')
   ,process_id                    NUMERIC(10)
   ,activity_id                   NUMERIC(10)
   ,sub_task_sequence             NUMERIC(10)
   ,sub_task_description          VARCHAR(100)
   ,error_code                    VARCHAR(10)
   ,error_message                 VARCHAR(200)
   ,occurred_at                   TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER INDEX errors_pkey SET TABLESPACE cf_logs_idx;
ALTER TABLE errors
        ADD CONSTRAINT errors_fkey
               FOREIGN KEY (process_id)
            REFERENCES process(id);

CREATE INDEX errors_fkey
          ON errors(process_id)
  TABLESPACE cf_logs_idx;

ALTER TABLE errors
        ADD CONSTRAINT errors_act_fkey
               FOREIGN KEY (activity_id)
            REFERENCES activity(id);

CREATE INDEX errors_act_fkey
          ON errors(activity_id)
  TABLESPACE cf_logs_idx;

CREATE SEQUENCE client_id_sq
     START WITH 1
   INCREMENT BY 1;

CREATE TABLE clients
(
   id                             NUMERIC(10) PRIMARY KEY DEFAULT NEXTVAL('client_id_sq')
  ,client_ip                      VARCHAR(15)
  ,client_port                    NUMERIC(10)
  ,thread_id                      INTEGER
  ,socket_fd                      INTEGER
  ,uses_ssl                       CHAR(1)
  ,last_synchronized_on           TIMESTAMP
  ,last_connected_on              TIMESTAMP
  ,last_disconnected_at           TIMESTAMP
  ,connected                      CHAR(1)
  ,client_type                    VARCHAR(10) -- Big-Top (the developer UI), ETL-App (Application executing)
);

ALTER INDEX clients_pkey SET TABLESPACE cf_logs_idx;

CREATE UNIQUE INDEX clients_ukey
                 ON clients(client_ip,client_port);


