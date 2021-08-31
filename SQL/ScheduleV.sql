-- $Header ScheduleV.sql 0.01 27-May-2009 Jerry
/*---------------------------------------------------------------------------*\
   File Name  : ScheduleV.sql
   Author     : Jerry Thomas
   Version    : 0.01
   Created On : 11-Dec-2007

   Purpose    : Store the the schedule views.

 so far this should work for all kinds of schedules.
 creating the time limit entries may become complicated

 Schedules for different times of the day & specific timed runs
 Types of schedules
1 Automatic runs for incremental extraction. only needs to have a time to
run , extract in parallel load in sequence
--2 Scheduled at specific times of the day or dates. This one has to run at
the specified times.
--3 File or other trigger based. Can be treated as 1, however the file should
trigger a specific instance only Say date based.
4 Dependencies that should run immediately after the predecessor has run
Schedule Type {AUTO,TRIGGER,TIMED,
 All requests should be selected in sequence of dates
 No request should be running for same entity
 No request should be running for same entity
1. all active data xfer (hold/enabled)
2. should not have any "wait" dependencies which have not completed to the
same or greater end date
3. should have < max_parallel extractions running at the time
4. should not have any dependencies or conflicts running at the same time
5. should obey the limits if imposed.
6. Reprocessing instances should have higher priority
7. should not have more than max reprocess errors for the reprocessed
instances
--8. should not allow a process with dates > any errored process if the
(maintain integrity flag is set) - this will also control whether the loads
should be sequential or parallel

-- Should be segmente as queries for auto, timed, reprocess,
-- need additional views for checking if the interface can proceed with the
load or it should wait.
-- core.ready_for_load_v
-- core.

-- Need to fix the performance issue in core.timed_schedule_v this causes the core.runnable view run for 3-4 seconds

\*---------------------------------------------------------------------------*/


DROP VIEW IF EXISTS core.runnable_v;
DROP VIEW IF EXISTS core.triggered_v;
DROP VIEW IF EXISTS core.tasks_timed_v;
DROP VIEW IF EXISTS core.tasks_auto_v;

DROP VIEW IF EXISTS core.auto_schedule_v;
DROP VIEW IF EXISTS core.timed_schedule_v;

--------------------------------------------------------------------------------
-- View Name  : timed_schedule_v
-- Author     : Jerry Thomas
-- Version    : 0.01
-- Created On : 26-May-2009

-- Purpose    : Schedules for the time based scheduled tasks
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW core.timed_schedule_v
AS
SELECT s.id
      ,s.rule
      ,tt.day_of_week
      ,tt.time_of_day
      ,tt.week
      ,tt.month
      ,tt.day_of_month
      ,tt.run_strt_ts
      ,tt.run_stop_ts
      ,c.date
      ,c.date + tt.time_of_day                   AS schedule_ts
  FROM core.schedule    s
      ,core.timetable   tt
      ,core.calendar    c
 WHERE tt.schedule_id                                     = s.id
   AND tt.is_restriction                                  = FALSE
   AND c.date                                            <= NOW() - tt.time_of_day
   AND COALESCE(tt.day_of_week  ,c.dow)                   = c.dow
   AND COALESCE(tt.month        ,c.month)                 = c.month
   AND core.DayOf(c.date,COALESCE(tt.day_of_month,c.day)) = c.day
   AND CURRENT_TIME                                 BETWEEN tt.run_strt_ts
                                                        AND tt.run_stop_ts
   AND NOT EXISTS (SELECT 1
                     FROM core.timetable   ttx
                    WHERE ttx.schedule_id    = s.id
                      AND ttx.is_restriction = TRUE
                      AND COALESCE(ttx.day_of_week,EXTRACT(DOW FROM NOW())) = EXTRACT(DOW FROM NOW())
                      AND CURRENT_TIME   BETWEEN ttx.run_strt_ts
                                             AND ttx.run_stop_ts);
--------------------------------------------------------------------------------
-- View Name  : auto_schedule_v
-- Author     : Jerry Thomas
-- Version    : 0.01
-- Created On : 26-May-2009

-- Purpose    : Schedules for the auto incremental tasks
-- Comments   : Tasks run now based on the allowed execution times defined in
--              the schedule
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW core.auto_schedule_v
AS
SELECT s.id
      ,s.rule
      ,tt.day_of_week
      ,tt.time_of_day
      ,tt.week
      ,tt.month
      ,tt.day_of_month
      ,tt.run_strt_ts
      ,tt.run_stop_ts
      ,c.date
      ,c.date::TIMESTAMP WITH TIME ZONE        AS schedule_ts
  FROM core.schedule    s
      ,core.timetable   tt
      ,core.calendar    c
 WHERE tt.schedule_id                                     = s.id
   AND tt.is_restriction                                  = FALSE
   AND c.date                                             = CURRENT_DATE
   AND COALESCE(tt.day_of_week  ,c.dow)                   = c.dow
   AND COALESCE(tt.month        ,c.month)                 = c.month
   AND core.DayOf(c.date,COALESCE(tt.day_of_month,c.day)) = c.day
   AND CURRENT_TIME                                 BETWEEN tt.run_strt_ts
                                                        AND tt.run_stop_ts
   AND NOT EXISTS (SELECT 1
                     FROM core.timetable   ttx
                    WHERE ttx.schedule_id = s.id
                      AND ttx.is_restriction = TRUE
                      AND COALESCE(ttx.day_of_week,EXTRACT(DOW FROM NOW())) = EXTRACT(DOW FROM NOW())
                      AND CURRENT_TIME   BETWEEN ttx.run_strt_ts
                                             AND ttx.run_stop_ts);

--------------------------------------------------------------------------------
-- View Name  : tasks_timed_v
-- Author     : Jerry Thomas
-- Version    : 0.01
-- Created On : 26-May-2009

-- Purpose    : Granular schedules for individual tasks that run at specified
--              times and days
--------------------------------------------------------------------------------
-- App should update the executed schedule_ts into last_run_on
CREATE OR REPLACE VIEW core.tasks_timed_v
AS
SELECT t.id                                                   AS id
      ,t.name                                                 AS name
      ,t.executable
      ,t.slicing_mode
      ,t.logging_mode
      ,t.process_mode
      ,t.dynamic_split
      ,t.ts_start_with                                        AS schedule_ts
      ,asv.schedule_ts + t.process_offset                     AS ts_lower_bound
      ,asv.schedule_ts + t.process_offset + t.ts_increment_by AS ts_upper_bound
      ,NULL::NUMERIC                                          AS ns_lower_bound
      ,NULL::NUMERIC                                          AS ns_upper_bound
      ,t.max_retries
      ,t.max_running
      ,t.hold_applied
      ,t.ts_start_with
      ,t.enabled
      ,t.allow_gaps
      ,t.allow_parallel_load
      ,t.process_offset
  FROM core.task                t
      ,core.timed_schedule_v   asv
 WHERE t.schedule_id     = asv.id
   AND t.process_mode    = 'TIMED'
   AND t.slicing_mode    = 'TIME'
   AND t.ts_start_with   = asv.schedule_ts;
   --AND t.ts_start_with  <= NOW();
   --AND asv.schedule_ts  <= NOW();

-- remember to set slice_last_run to ts_upper_bound - process_offset
--------------------------------------------------------------------------------
-- View Name  : tasks_auto_v
-- Author     : Jerry Thomas
-- Version    : 0.01
-- Created On : 26-May-2009

-- Purpose    : Granular schedules for individual incremental tasks that run
--              automatically
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW core.tasks_auto_v
AS
SELECT t.id
      ,t.name
      ,t.executable
      ,t.slicing_mode
      ,t.logging_mode
      ,t.process_mode
      ,t.dynamic_split
      ,asv.schedule_ts + t.process_offset                               AS schedule_ts
      ,t.ts_start_with                                                  AS ts_lower_bound
      ,LEAST((CASE WHEN (COALESCE(t.ts_increment_by,'00:00:00') = '00:00:00') THEN
                     CURRENT_DATE + t.process_offset
                   ELSE
                     t.ts_start_with + t.ts_increment_by
               END)
             ,CURRENT_DATE + t.process_offset)                          AS ts_upper_bound
      ,ns_start_with                                                    AS ns_lower_bound
      ,NULL::NUMERIC                                                    AS ns_upper_bound
      ,t.max_retries
      ,t.max_running
      ,t.hold_applied
      ,t.ts_start_with
      ,t.enabled
      ,t.allow_gaps
      ,t.allow_parallel_load
      ,t.process_offset
  FROM core.task                t
      ,core.auto_schedule_v   asv
 WHERE t.schedule_id           = asv.id
   AND t.process_mode          = 'AUTO'
   AND t.slicing_mode          = 'TIME';

--------------------------------------------------------------------------------
-- View Name  : auto_precursor_runs_v
-- Author     : Jerry Thomas
-- Version    : 0.01
-- Created On : 04-Jun-2009

-- Purpose    : Lists the status of the most recent precursors that should be
--              processed for the auto incremental tasks
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW core.auto_precursor_runs_v
AS
SELECT c.id
      ,c.precursor_id
      ,c.successor_id
      ,c.kind
      ,p.task_id
      ,COALESCE(p.ts_upper_bound,CURRENT_DATE)   AS ts_upper_bound
      ,pt.name                                   AS precursor_name
      ,p.status                                  
      ,p.scheduled_at
      ,p.initiated_at
      ,p.completed_at
  FROM core.chain   c
       INNER JOIN      core.task    pt ON (    pt.id             = c.precursor_id
                                           AND pt.enabled        = TRUE
                                           AND pt.process_mode   = 'AUTO')
       LEFT OUTER JOIN logs.process p  ON (    p.task_id         = c.precursor_id
                                           AND p.status          = 'Sucessful'
                                           AND p.reprocessed     = FALSE
                                           AND p.ts_upper_bound >= CURRENT_DATE
                                                                   - (CASE WHEN CURRENT_TIME < pt.process_offset::TIME
                                                                           THEN '1 Day'
                                                                           ELSE '0'
                                                                       END)::interval)
 WHERE c.enabled   = TRUE;
--------------------------------------------------------------------------------
-- View Name  : runnable_v
-- Author     : Jerry Thomas
-- Version    : 0.01
-- Created On : 26-May-2009

-- Purpose    : Tasks that are runnable now based on their schedules

-- comments   : the view may need to be modified for schedlues like the one below
--              run on the 1st of the month repeat for three days
--              in this case the ts_lower_bound and ts_upper_bound should remain the same
-- TIMED interface CASCADE dependencies are based on the precursors having the same scheduled time (if a daily once interface depends on the hourly task the scheduled time should match at least one of the hourly task schedule times.
--   in case a task with a different schedule has to be dependant on the
--   precursor task this scheduling method will not work
-- Will need to see if a valid scenario exists for this case
--   Alternatively a conflict dependency can be set to ensure that the precursors
--  are not running at the same time

--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW core.runnable_v
AS
-- Automatic incremental tasks
SELECT t.id
      ,t.name
      ,t.slicing_mode
      ,t.logging_mode
      ,t.process_mode
      ,t.dynamic_split
      ,t.schedule_ts
      ,t.ts_lower_bound
      ,t.ts_upper_bound
      ,t.ns_lower_bound
      ,t.ns_upper_bound
      ,t.max_retries
      ,t.max_running
      ,t.hold_applied
      ,t.ts_start_with
      ,NULL::NUMERIC                AS old_process_id
  FROM core.tasks_auto_v  t
 WHERE t.enabled         = TRUE
   --AND t.slicing_mode    = 'TIME'
   AND t.schedule_ts    <= NOW()
   AND t.ts_lower_bound  < CURRENT_DATE + CURRENT_TIME - t.process_offset
   AND t.ts_lower_bound  < t.ts_upper_bound
   -- All Key reference dependencies should have completed till the highest scheduled slice
   AND TRUE = (SELECT (CASE WHEN COUNT(DISTINCT apr.task_id) = COUNT(DISTINCT apr.precursor_id) THEN TRUE
                            WHEN COUNT(DISTINCT apr.precursor_id) = 0 THEN TRUE
                            ELSE FALSE END)
                 FROM core.auto_precursor_runs_v apr
                WHERE apr.kind           IN ('KEY','CASCADE')
                  AND apr.successor_id    = t.id
                  AND apr.ts_upper_bound <= t.schedule_ts
               )
   -- No dependency should be running
   AND NOT EXISTS (SELECT c.id
                     FROM core.chain   c
                         ,logs.process p
                    WHERE c.successor_id      = t.id
                      AND p.task_id           = c.precursor_id
                      AND p.reprocessed       = FALSE
                      AND p.status       NOT IN  ('Sucessful','Failed','Killed')) -- as good as checking p.completed_at is not null
   -- Earlier process that has failed should be reprocessed first, assuming that gaps are not allowed
   AND NOT EXISTS (SELECT p.id
                     FROM logs.process p
                    WHERE p.task_id               = t.id
                      AND t.allow_gaps            = FALSE
                      AND p.status                = 'Failed'
                      AND p.reprocessed           = FALSE
                      AND p.ts_lower_bound        < t.ts_lower_bound)
   -- Don't pick up any task where the number of running instances is already up to max allowed
   AND (   max_running = 0
        OR max_running > (SELECT COUNT(p.id)
                            FROM logs.process p
                           WHERE p.task_id                   = t.id
                             AND COALESCE(p.stage,'Extract') = 'Extract'
                             AND p.status      NOT IN ('Sucessful','Failed','Killed')
                         )
       )
UNION ALL
-- Scheduled tasks
SELECT t.id
      ,t.name
      ,t.slicing_mode
      ,t.logging_mode
      ,t.process_mode
      ,t.dynamic_split
      ,t.schedule_ts
      ,t.ts_lower_bound
      ,t.ts_upper_bound
      ,t.ns_lower_bound
      ,t.ns_upper_bound
      ,t.max_retries
      ,t.max_running
      ,t.hold_applied
      ,t.ts_start_with
      ,NULL::NUMERIC                AS old_process_id
  FROM core.tasks_timed_v  t
 WHERE t.enabled       = TRUE
   AND t.slicing_mode  = 'TIME'
   AND t.schedule_ts  <= NOW()
   -- All precursors for the same schedule should have completed successfully
   AND TRUE = (SELECT (CASE WHEN (    COUNT(p.id) > 0
                                  AND COUNT(f.id) = 0)  THEN TRUE
                            WHEN COUNT(DISTINCT c.id)>0 THEN FALSE
                            ELSE TRUE
                        END)
                 FROM core.chain   c
                      LEFT OUTER JOIN logs.process p  ON (    c.precursor_id = p.task_id
                                                          AND p.status       = 'Sucessful'
                                                          AND p.reprocessed  = FALSE)
                      LEFT OUTER JOIN logs.process f  ON (    c.precursor_id = f.task_id
                                                          AND f.status       = 'Failed'
                                                          AND f.reprocessed  = FALSE)
                WHERE c.kind                                   = 'CASCADE'
                  AND c.enabled                                = TRUE
                  AND c.successor_id                           = t.id
                  AND COALESCE(p.scheduled_at,current_date)    = COALESCE(f.scheduled_at,current_date)
                  AND COALESCE(p.scheduled_at,t.schedule_ts)   = t.schedule_ts)
   -- No conflicting dependencies should be running
   AND NOT EXISTS (SELECT c.id
                     FROM core.chain   c
                         ,logs.process p
                    WHERE c.successor_id      = t.id
                      AND p.task_id           = c.precursor_id
                      AND c.kind              = 'CONFLICT'
                      AND c.enabled           = TRUE
                      AND p.reprocessed       = FALSE
                      AND p.status       NOT IN  ('Sucessful','Failed','Killed'))
   -- Don't pick up any task where the number of running instances is already up to max allowed
   AND (   max_running = 0
        OR max_running > (SELECT COUNT(p.id)
                            FROM logs.process p
                           WHERE p.task_id          = t.id
                             AND p.status      NOT IN ('Sucessful','Failed','Killed')
                         )
       )
UNION ALL
--Auto reprocess error interfaces
SELECT t.id
      ,t.name
      ,t.slicing_mode
      ,t.logging_mode
      ,t.process_mode
      ,t.dynamic_split
      ,p.scheduled_at
      ,p.ts_lower_bound
      ,p.ts_upper_bound
      ,p.ns_lower_bound
      ,p.ns_upper_bound
      ,t.max_retries
      ,t.max_running
      ,t.hold_applied
      ,t.ts_start_with
      ,COALESCE(p.original_process_id,p.id)                        AS old_process_id
  FROM logs.process        p
      ,core.task           t
 WHERE t.id             = p.task_id
   AND p.status         = 'Failed'
   AND p.reprocessed    = FALSE
   AND p.completed_at  <= NOW() - t.retry_interval
   -- No dependencies should be running
   AND NOT EXISTS (SELECT c.id
                     FROM core.chain   c
                         ,logs.process p
                    WHERE c.successor_id      = t.id
                      AND p.task_id           = c.precursor_id
                     -- AND c.kind              = 'CONFLICT'
                      AND p.reprocessed       = FALSE
                      AND p.status       NOT IN  ('Sucessful','Failed','Killed'))
   -- Don't pick up any task where the number of running instances is al'Failed'ready up to max allowed
   AND (   max_running = 0
        OR max_running > (SELECT count(p.id)
                            FROM logs.process p
                           WHERE p.task_id          = t.id
                             AND p.status      NOT IN ('Sucessful','Failed','Killed')
                         )
       )
   -- Don't reprocess more than the allowed number of errors
   AND (   max_retries > (SELECT COUNT(px.id)
                            FROM logs.process px
                           WHERE px.task_id             = t.id
                             AND px.status              = ('Failed')
                             AND px.reprocessed         = FALSE
                             AND COALESCE(px.original_process_id,p.id) = COALESCE(p.original_process_id,p.id)
                         )
       );


--------------------------------------------------------------------------------
-- View Name  : triggered_v
-- Author     : Jerry Thomas
-- Version    : 0.01
-- Created On : 26-May-2009

-- Purpose    : Tasks that are trigerred by file or external
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW core.triggered_v
AS
SELECT t.id                                                              AS id
      ,t.name                                                            AS name
      ,t.executable
      ,t.slicing_mode
      ,t.logging_mode
      ,t.process_mode
      ,t.dynamic_split
      ,NOW()                                                             AS schedule_ts
      ,(CASE WHEN position('+' IN pattern_replace) > 0 THEN
              SUBSTR(pattern_replace,0,position('+' IN pattern_replace))
            ELSE
              pattern_replace
            END)                                                         AS pattern_date
      ,(CASE WHEN position('+' IN pattern_replace) > 0 THEN
              SUBSTR(pattern_replace,position('+' IN pattern_replace)+1)
            ELSE
              NULL
            END)                                                         AS pattern_interval
      ,ts_increment_by
      ,t.max_retries
      ,t.max_running
      ,t.hold_applied
      ,t.ts_start_with
      ,t.enabled
      ,t.allow_gaps
      ,t.allow_parallel_load
      ,t.process_offset
      ,t.pattern_match
      ,t.date_format
  FROM core.task      t
 WHERE t.enabled       = TRUE
   AND t.process_mode  = 'TRIGGER';
