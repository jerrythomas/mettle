-- $Header LoggersF.sql 1.00 05-Jun-2009 Jerry Thomas
--------------------------------------------------------------------------------
--  JTActivityLog.m
--  Mettle
--
--  Created by Jerry Thomas on 6/10/09.
--  Copyright 2009 Jerry Thomas. All rights reserved.
--------------------------------------------------------------------------------

-- Updates the unix pid for the task spawned and also marks the process as
-- launched. Returns true if update was successful
CREATE OR REPLACE FUNCTION logs.process_launch(in_pid    NUMERIC   -- id of the process
                                              ,in_ospid  NUMERIC)  -- id of the os process
RETURNS BOOLEAN
AS $$
DECLARE
   num_rows  NUMERIC := 0;
BEGIN
   UPDATE logs.process
      SET status       = 'Launched'
         ,os_pid       = in_ospid
    WHERE id = in_pid;

   GET DIAGNOSTICS num_rows = ROW_COUNT;

   RETURN (num_rows = 1);
EXCEPTION
   WHEN OTHERS THEN
      RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- Function   : logs.process_mark
-- Author     : Jerry Thomas
-- Version    : 1.00
-- Created On : 05-Jun-2009

-- Returns    : True if update was successful

-- Purpose    : Updates the status of the process
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION logs.process_mark(in_pid    NUMERIC   -- id of the process
                                            ,in_status VARCHAR)  -- kind of the stage
RETURNS BOOLEAN
AS $$
DECLARE
   num_rows    NUMERIC := 0;
   log_task_id NUMERIC := 0;   
BEGIN
   -- Both of these should go through or it will create an inconsistency
   SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
   
   SELECT log_task_id = task_id
     FROM logs.process 
    WHERE process_id = in_pid;
     
   -- Mark the current status
   UPDATE logs.process
      SET status       = in_status
         ,completed_at = (CASE WHEN in_status IN ('Successful','Failed','Killed','Crashed')
                               THEN NOW()
                               ELSE completed_at
                           END)
         ,run_duration = NOW() - initiated_at
         ,process_id   = NULL
    WHERE process_id = in_pid;
   GET DIAGNOSTICS num_rows = ROW_COUNT;
   
   -- Set the count of running and faled for the task
   UPDATE core.task
      SET currently_running  = (SELECT COUNT(p.id) 
                                  FROM logs.process p 
                                 WHERE p.task_id = t.id
                                   AND completed_at IS NOT NULL)
         ,awaiting_reprocess = (SELECT COUNT(p.id) 
                                  FROM logs.process p 
                                 WHERE p.task_id = t.id
                                   AND p.status IN ('Failed','Killed','Crashed')
                                   AND p.reprocessed = false)
    WHERE id = log_task_id;
     
   COMMIT;
   
   -- Generate a notification for trigerring successors.
   IF (num_rows = 1) THEN                                                 
       NOTIFY CF_COMPLETED_A_TASK;
   END IF;

   RETURN (num_rows = 1);
EXCEPTION
   WHEN OTHERS THEN
      RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- Function   : logs.stage_init
-- Author     : Jerry Thomas
-- Version    : 1.00
-- Created On : 05-Jun-2009

-- Returns    : the id of the stage created

-- Purpose    : Logging the stage initialization
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION logs.stage_init(in_pid  NUMERIC   -- id of the process
                                          ,in_kind VARCHAR)  -- kind of the stage
RETURNS NUMERIC
AS $$
DECLARE
   stg_id  numeric := 0;
BEGIN
   --stg_id = NEXTVAL('logs.stage_id_sq');
   INSERT INTO logs.stage(/*id,*/process_id,kind,initiated_at)
   VALUES (/*stg_id,*/in_pid,in_kind,NOW());

   stg_id = CURRVAL('logs.stage_id_sq');
   UPDATE logs.process
      SET stage = s.kind
     FROM logs.stage s
    WHERE s.id = stg_id;

   RETURN stg_id;
EXCEPTION
   WHEN OTHERS THEN
      RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- Function   : logs.stage_waitedfor
-- Author     : Jerry Thomas
-- Version    : 1.00
-- Created On : 05-Jun-2009

-- Purpose    : Logging the wait duration of a stage and reason for the wait
--              Will primarily be used by the load stage which may wait for
--              a previous slice's load to complete
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION logs.stage_waitedfor(in_id     NUMERIC  -- stage id
                                               ,in_reason VARCHAR) -- reason for the wait
RETURNS BOOLEAN
AS $$
DECLARE
   num_rows  NUMERIC := 0;
BEGIN
   UPDATE logs.stage
      SET wait_duration= NOW() - initiated_at
         ,wait_reason  = in_reason
    WHERE id = in_id;

   GET DIAGNOSTICS num_rows = ROW_COUNT;

   UPDATE logs.process p
      SET p.wait_duration = COALESCE(p.wait_duration,0) + s.wait_duration
     FROM logs.stage s
    WHERE s.id = in_id
      AND p.id = s.process_id;


   RETURN (num_rows > 0);
EXCEPTION
   WHEN OTHERS THEN
      RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- Function   : logs.stage_mark
-- Author     : Jerry Thomas
-- Version    : 1.00
-- Created On : 05-Jun-2009

-- Purpose    : Marks the completing status of the stage and updates the rows
--              processed. Also updates the value into the appropriate slot in
--              the process log
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION logs.stage_mark(in_id     NUMERIC  -- stage id
                                          ,in_status VARCHAR  -- status of stage
                                          ,in_rows   NUMERIC) -- rows processed
RETURNS BOOLEAN
AS $$
DECLARE
   num_rows  NUMERIC := 0;
BEGIN
   UPDATE logs.stage
      SET completed_at   = NOW()
         ,duration       = NOW() - initiated_at
         ,rows_processed = in_rows
         ,status         = in_status
    WHERE id = in_id;

   UPDATE logs.process p
      SET rows_extracted   = (CASE WHEN s.kind = 'Extract'   THEN
                                        s.rows_processed
                                   ELSE rows_extracted
                               END)
         ,rows_loaded      = (CASE WHEN s.kind = 'Load'      THEN
                                        s.rows_processed
                                   ELSE rows_loaded
                               END)
         ,rows_rejected    = (CASE WHEN s.kind = 'Reject'    THEN
                                        s.rows_processed
                                   ELSE rows_rejected
                               END)
         ,rows_transformed = (CASE WHEN s.kind = 'Transform' THEN
                                        s.rows_processed
                                   ELSE rows_transformed
                               END)
     FROM logs.stage s
    WHERE s.id = in_id
      AND p.id = s.process_id;

   GET DIAGNOSTICS num_rows = ROW_COUNT;

   RETURN (num_rows > 0);
EXCEPTION
   WHEN OTHERS THEN
      RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- Function   : logs.activity_init
-- Author     : Jerry Thomas
-- Version    : 1.00
-- Created On : 05-Jun-2009

-- Returns    : the id of the activity created

-- Purpose    : Logging the initialization of an activity in a stage
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION logs.activity_init(in_stage       NUMERIC   -- id of the stage
                                             ,in_name        VARCHAR   -- name of the activity (or component)
                                             ,in_loglevel    INTEGER   -- logging level
                                             ,in_thread      VARCHAR   -- thread info
                                             ,in_server      VARCHAR)  -- server that executed
RETURNS NUMERIC
AS $$
DECLARE
   act_id  numeric := 0;
BEGIN
   -- id is automatically set
   --act_id = NEXTVAL('logs.activity_id_sq');
   INSERT INTO logs.activity(/*id
                            ,*/stage_id
                            ,name
                            ,log_level
                            ,path
                            ,executed_by
                            ,initiated_at
                            ,status
                            ,execution_seq)
   VALUES( /*act_id
          ,*/in_stage
          ,in_name
          ,in_loglevel
          ,in_thread
          ,in_server
          ,NOW()
          ,'Initiated'
          ,(SELECT coalesce(MAX(execution_seq),0)+1 FROM logs.activity WHERE stage_id = in_stage));

   act_id = CURRVAL('logs.activity_id_sq');
   RETURN act_id;
EXCEPTION
   WHEN OTHERS THEN
      RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- Function   : logs.activity_mark
-- Author     : Jerry Thomas
-- Version    : 1.00
-- Created On : 05-Jun-2009

-- Purpose    : Marks the completing status of the activity and updates the rows
--              processed.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION logs.activity_mark(in_id     NUMERIC  -- activity id
                                             ,in_status VARCHAR  -- status of activity
                                             ,in_rows   NUMERIC) -- rows processed
RETURNS BOOLEAN
AS $$
DECLARE
   num_rows  NUMERIC := 0;
BEGIN
   UPDATE logs.activity
      SET completed_at   = NOW()
         ,duration       = NOW() - initiated_at
         ,rows_processed = in_rows
         ,status         = in_status
    WHERE id = in_id;

   GET DIAGNOSTICS num_rows = ROW_COUNT;

   RETURN (num_rows > 0);
EXCEPTION
   WHEN OTHERS THEN
      RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- Function   : logs.activity_detail
-- Author     : Jerry Thomas
-- Version    : 1.00
-- Created On : 05-Jun-2009

-- Purpose    : Updates additional details for the activity.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION logs.activity_detail(in_id     NUMERIC  -- activity id
                                               ,in_type   VARCHAR  -- type of activity
                                               ,in_desc   NUMERIC) -- description/query/formula used
RETURNS BOOLEAN
AS $$
DECLARE
   num_rows  NUMERIC := 0;
BEGIN
   UPDATE logs.activity
      SET type_name   = in_type
         ,description = in_desc
    WHERE id = in_id;

   GET DIAGNOSTICS num_rows = ROW_COUNT;

   RETURN (num_rows > 0);
EXCEPTION
   WHEN OTHERS THEN
      RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- Function   : logs.activity_failed
-- Author     : Jerry Thomas
-- Version    : 1.00
-- Created On : 05-Jun-2009

-- Purpose    : Updates additional details for the activity.
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION logs.activity_failed(in_id     NUMERIC  -- activity id
                                               ,in_desc   VARCHAR  -- description of the step
                                               ,in_errcd  VARCHAR  -- error code
                                               ,in_errmsg VARCHAR) -- error message
RETURNS BOOLEAN
AS $$
DECLARE
   num_rows  NUMERIC := 0;
BEGIN
   INSERT INTO logs.errors(activity_id
                          ,sub_task_description
                          ,error_code
                          ,error_message)
   VALUES(in_id
         /*process_id  = (select id
                           from logs.process  p
                               ,logs.stage    s
                               ,logs.activity a
                          where a.id = in_id
                            and s.id = a.stage_id
                            and p.id = s.process_id)*/
         ,in_desc
         ,in_errcd
         ,in_errmsg);

   GET DIAGNOSTICS num_rows = ROW_COUNT;

   RETURN (num_rows > 0);
EXCEPTION
   WHEN OTHERS THEN
      RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;