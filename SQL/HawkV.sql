-- $Header Hawk.sql 0.01 02-Jun-2009 Jerry
/*
 * File Name  : Hawk.sql
 * Purpose    : Table definitions for analytical reporting on the progress.
 * Author     : Jerry Thomas
 * Version    : 0.01
 * Created On : 12-May-2009
 */

CREATE OR REPLACE VIEW core.wait_reasons_v
AS
   SELECT id
         ,name
         ,'Task is currently disabled.'                                                  AS reason
         ,NULL::TIMESTAMP                                                                AS scheduled_at
         ,ts_start_with                                                                  AS ts_lower_bound
         ,NULL::VARCHAR                                                                  AS waiting_for
         ,NULL::NUMERIC                                                                  AS waiting_for_id
         ,process_mode
         ,slicing_mode
     FROM core.task
    WHERE enabled = FALSE
UNION ALL
   SELECT id
         ,name
         ,'No Schedule assigned to the task'                                             AS reason
         ,NULL::TIMESTAMP                                                                AS scheduled_at
         ,ts_start_with                                                                  AS ts_lower_bound
         ,NULL::VARCHAR                                                                  AS waiting_for
         ,NULL::NUMERIC                                                                  AS waiting_for_id
         ,process_mode
         ,slicing_mode
     FROM core.task
    WHERE enabled = TRUE
      AND schedule_id IS NULL
UNION ALL
   SELECT t.id
         ,t.name
         ,'Maximum allowed '||t.max_running||' instances in extract stage has reached.'  AS reason
         ,CURRENT_DATE+t.process_offset                                                  AS scheduled_at
         ,t.ts_start_with                                                                AS ts_lower_bound
         ,NULL::VARCHAR                                                                  AS waiting_for
         ,NULL::NUMERIC                                                                  AS waiting_for_id
         ,t.process_mode
         ,t.slicing_mode
     FROM core.task  t
         ,logs.process p
    WHERE p.task_id                        = t.id
      AND t.enabled                        = TRUE
      AND t.max_running                    > 0
      AND t.process_mode                   = 'AUTO'
      AND COALESCE(p.stage,'EXTRACT')      = 'EXTRACT'
      AND p.status                    NOT IN ('SUCCESS','FAILURE','KILLED')
 GROUP BY t.id,t.name,t.max_running,t.process_offset,t.ts_start_with,t.process_mode,t.slicing_mode
   HAVING COUNT(p.id) > t.max_running
UNION ALL
   SELECT t.id
         ,t.name
         ,'Maximum allowed '||t.max_running||' instances has reached.'                   AS reason
         ,NULL::TIMESTAMP                                                                AS scheduled_at
         ,ts_start_with                                                                  AS ts_lower_bound
         ,NULL::VARCHAR                                                                  AS waiting_for
         ,NULL::NUMERIC                                                                  AS waiting_for_id
         ,t.process_mode
         ,t.slicing_mode
     FROM core.task  t
         ,logs.process p
    WHERE p.task_id                        = t.id
      AND t.enabled                        = TRUE
      AND t.max_running                    > 0
      AND t.process_mode                   = 'TIMED'
      AND p.status                    NOT IN ('SUCCESS','FAILURE','KILLED')
 GROUP BY t.id,t.name,t.max_running,t.ts_start_with,t.process_mode,t.slicing_mode
   HAVING COUNT(p.id) > t.max_running
UNION ALL
   SELECT t.id
         ,t.name
         ,'Scheduled to run in the future.'                                             AS reason
         ,t.schedule_ts                                                                 AS scheduled_at
         ,t.ts_lower_bound
         ,NULL::VARCHAR                                                                 AS waiting_for
         ,NULL::NUMERIC                                                                 AS waiting_for_id
         ,t.process_mode
         ,t.slicing_mode
     FROM core.tasks_timed_v t
    WHERE t.schedule_ts > NOW()
      --AND t.schedule_ts < CURRENT_DATE + '1 Day' ::INTERVAL
      AND t.enabled     = TRUE
      AND (   t.max_running = 0
           OR t.max_running > (SELECT COUNT(p.id)
                                 FROM logs.process p
                                WHERE p.task_id          = t.id
                                  AND p.status      NOT IN ('SUCCESS','FAILURE','KILLED')
                              )
          )
      AND NOT EXISTS (SELECT c.id
                        FROM core.chain   c
                            ,logs.process p
                       WHERE c.successor_id      = t.id
                         AND p.task_id           = c.precursor_id
                         AND c.kind              = 'CONFLICT'
                         AND c.enabled           = TRUE
                         AND p.reprocessed       = FALSE
                         AND p.status       NOT IN  ('SUCCESS','FAILURE','KILLED'))
      AND TRUE = (SELECT (CASE WHEN (    COUNT(p.id) > 0
                                     AND COUNT(f.id) = 0)  THEN TRUE
                               WHEN COUNT(DISTINCT c.id)>0 THEN FALSE
                               ELSE TRUE
                           END)
                    FROM core.chain   c
                         LEFT OUTER JOIN logs.process p  ON (    c.precursor_id = p.task_id
                                                             AND p.status       = 'SUCCESS'
                                                             AND p.reprocessed  = FALSE)
                         LEFT OUTER JOIN logs.process f  ON (    c.precursor_id = f.task_id
                                                             AND f.status       = 'FAILED'
                                                             AND f.reprocessed  = FALSE)
                   WHERE c.kind                                   = 'CASCADE'
                     AND c.successor_id                           = t.id
                     AND c.enabled                                = TRUE
                     AND COALESCE(p.scheduled_at,current_date)    = COALESCE(f.scheduled_at,current_date)
                     AND COALESCE(p.scheduled_at,t.schedule_ts)   = t.schedule_ts)
UNION ALL
   SELECT t.id
         ,t.name
         ,'Waiting for the conflicting task which is in progress.'                      AS reason
         ,t.schedule_ts                                                                 AS scheduled_at
         ,t.ts_lower_bound
         ,pt.name                                                                       AS waiting_for
         ,pt.id                                                                         AS waiting_for_id
         ,t.process_mode
         ,t.slicing_mode
     FROM core.tasks_timed_v t
         ,core.chain         c
         ,logs.process       p
         ,core.task          pt
    WHERE c.successor_id      = t.id
      AND c.kind              = 'CONFLICT'
      AND c.enabled           = TRUE
      AND p.task_id           = c.precursor_id
      AND pt.id               = c.precursor_id
      AND p.reprocessed       = FALSE
      AND p.status       NOT IN  ('SUCCESS','FAILURE','KILLED')
      AND schedule_ts        <= NOW()
      AND TRUE = (SELECT (CASE WHEN (    COUNT(p.id) > 0
                                     AND COUNT(f.id) = 0)  THEN TRUE
                               WHEN COUNT(DISTINCT c.id)>0 THEN FALSE
                               ELSE TRUE
                           END)
                    FROM core.chain   c
                         LEFT OUTER JOIN logs.process p  ON (    c.precursor_id = p.task_id
                                                             AND p.status       = 'SUCCESS'
                                                             AND p.reprocessed  = FALSE)
                         LEFT OUTER JOIN logs.process f  ON (    c.precursor_id = f.task_id
                                                             AND f.status       = 'FAILED'
                                                             AND f.reprocessed  = FALSE)
                   WHERE c.kind                                   = 'CASCADE'
                     AND c.successor_id                           = t.id
                     AND c.enabled                                = TRUE
                     AND COALESCE(p.scheduled_at,current_date)    = COALESCE(f.scheduled_at,current_date)
                     AND COALESCE(p.scheduled_at,t.schedule_ts)   = t.schedule_ts)
      AND (   t.max_running = 0
           OR t.max_running > (SELECT COUNT(p.id)
                                 FROM logs.process p
                                WHERE p.task_id          = t.id
                                  AND p.status      NOT IN ('SUCCESS','FAILURE','KILLED')
                              )
          )
UNION ALL
   SELECT t.id
         ,t.name
         ,'Waiting for the precursor task which '
                   ||(CASE WHEN p.id IS NULL THEN
                             'is yet to run.'
                           WHEN p.status      = 'FAILURE' THEN
                             'has failed and needs to be reprocessed.'
                           WHEN p.status      = 'KILLED' THEN
                             'has been terminated and needs to be reprocessed.'
                           ELSE
                             'is running.'
                       END)                                                             AS reason
         ,t.schedule_ts                                                                 AS scheduled_at
         ,t.ts_lower_bound
         ,pt.name                                                                       AS waiting_for
         ,pt.id                                                                         AS waiting_for_id
         ,t.process_mode
         ,t.slicing_mode
     FROM core.tasks_timed_v     t
          INNER JOIN core.chain       c  ON (    c.successor_id = t.id
                                             AND c.enabled      = TRUE
                                             AND c.kind         = 'CASCADE')
          INNER JOIN core.task       pt  ON (    pt.id = c.precursor_id)
          LEFT OUTER JOIN logs.process p ON (    c.precursor_id    = p.task_id
                                             AND p.reprocessed     = FALSE
                                             AND p.scheduled_at = t.schedule_ts)
    WHERE c.enabled           = TRUE
      AND t.schedule_ts        <= NOW()
      AND COALESCE(p.status     ,'NOTRUN') != 'SUCCESS'
      AND NOT EXISTS (SELECT c.id
                        FROM core.chain   c
                            ,logs.process p
                       WHERE c.successor_id      = t.id
                         AND p.task_id           = c.precursor_id
                         AND c.kind              = 'CONFLICT'
                         AND c.enabled           = TRUE
                         AND p.reprocessed       = FALSE
                         AND p.status       NOT IN  ('SUCCESS','FAILURE','KILLED'))
      AND (   t.max_running = 0
           OR t.max_running > (SELECT COUNT(p.id)
                               FROM logs.process p
                              WHERE p.task_id          = t.id
                                AND p.status      NOT IN ('SUCCESS','FAILURE','KILLED')
                            )
       )
UNION ALL
   SELECT t.id
         ,t.name
         ,'Scheduled to run at a later time today.'                                     AS reason
         ,t.schedule_ts                                                                 AS scheduled_at
         ,t.ts_lower_bound
         ,NULL::VARCHAR                                                                 AS waiting_for
         ,NULL::NUMERIC                                                                 AS waiting_for_id
         ,t.process_mode
         ,t.slicing_mode
     FROM core.tasks_auto_v t
    WHERE t.enabled = TRUE
      AND t.schedule_ts     >= NOW()
      AND t.schedule_ts     < CURRENT_DATE + '1 Day'::INTERVAL
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
                         AND p.status       NOT IN  ('SUCCESS','FAILURE','KILLED'))
      -- Earlier process that has failed should be reprocessed first, assuming that gaps are not allowed
      AND NOT EXISTS (SELECT p.id
                        FROM logs.process p
                       WHERE p.task_id               = t.id
                         AND t.allow_gaps            = FALSE
                         AND p.status                = 'FAILURE'
                         AND p.reprocessed           = FALSE
                         AND p.ts_lower_bound        < t.ts_lower_bound)
      -- Don't pick up any task where the number of running instances is already up to max allowed
      AND (   max_running = 0
           OR max_running > (SELECT COUNT(p.id)
                               FROM logs.process p
                              WHERE p.task_id                   = t.id
                                AND COALESCE(p.stage,'EXTRACT') = 'EXTRACT'
                                AND p.status               NOT IN ('SUCCESS','FAILURE','KILLED')
                            )
          )
UNION ALL
   SELECT t.id
          ,t.name
          ,'Waiting for the precursor task which '
                    ||(CASE WHEN c.status IS NULL THEN
                              'is yet to run.'
                            WHEN c.status = 'FAILURE' THEN
                              'has failed and needs to be reprocessed.'
                            WHEN c.status = 'KILLED' THEN
                              'has been terminated and needs to be reprocessed.'
                            ELSE
                              'is running.'
                        END)                                                             AS reason
          ,t.schedule_ts                                                                 AS scheduled_at
          ,t.ts_lower_bound
          ,c.precursor_name                                                                       AS waiting_for
          ,c.task_id                                                                         AS waiting_for_id
          ,t.process_mode
          ,t.slicing_mode
      FROM core.tasks_auto_v t
           INNER JOIN core.auto_precursor_runs_v   c  ON (    c.successor_id = t.id
                                              AND c.kind         IN ('KEY','CASCADE'))
           /*INNER JOIN core.task       pt  ON (    pt.id = c.precursor_id)
           LEFT OUTER JOIN logs.process p ON (    c.precursor_id    = p.task_id
                                              AND p.reprocessed     = FALSE
                                              AND t.schedule_ts    >= p.ts_upper_bound
                                              --AND p.status         != 'SUCCESS'
                                              AND p.ts_upper_bound >= CURRENT_DATE
                                                                     - (CASE WHEN CURRENT_TIME < pt.process_offset::TIME
                                                                             THEN '1 Day' ELSE '0' END)::INTERVAL) */
     WHERE t.enabled          = TRUE
       AND t.schedule_ts     <= NOW()
       AND t.schedule_ts     < CURRENT_DATE + '1 Day'::INTERVAL
       AND t.ts_lower_bound  < CURRENT_DATE + CURRENT_TIME - t.process_offset
       AND t.ts_lower_bound  < t.ts_upper_bound
       AND COALESCE(c.status,'NOTRUN') != 'SUCCESS'
       -- Earlier process that has failed should be reprocessed first, assuming that gaps are not allowed
       AND NOT EXISTS (SELECT p.id
                         FROM logs.process p
                        WHERE p.task_id               = t.id
                          AND t.allow_gaps            = FALSE
                          AND p.status                = 'FAILURE'
                          AND p.reprocessed           = FALSE
                          AND p.ts_lower_bound        < t.ts_lower_bound)
       -- Don't pick up any task where the number of running instances is already up to max allowed
       AND (   t.max_running = 0
            OR t.max_running > (SELECT COUNT(p.id)
                                  FROM logs.process p
                                 WHERE p.task_id          = t.id
                                   AND COALESCE(p.stage,'EXTRACT') = 'EXTRACT'
                                   AND p.status      NOT IN ('SUCCESS','FAILURE','KILLED')
                               )
        )
UNION ALL
   SELECT t.id
         ,t.name
         ,'Waiting for the precursor task which is running.'                            AS reason
         ,t.schedule_ts                                                                 AS scheduled_at
         ,t.ts_lower_bound
         ,pt.name                                                                       AS waiting_for
         ,pt.id                                                                         AS waiting_for_id
         ,t.process_mode
         ,t.slicing_mode
     FROM core.tasks_auto_v t
          INNER JOIN core.chain       c  ON (    c.successor_id      = t.id
                                             AND c.enabled           = TRUE
                                             AND c.kind         NOT IN ('KEY','CASCADE'))
          INNER JOIN core.task       pt  ON (    pt.id = c.precursor_id)
          INNER JOIN logs.process    p   ON (    c.precursor_id    = p.task_id
                                             AND p.reprocessed     = FALSE
                                             AND p.status       NOT IN  ('SUCCESS','FAILURE','KILLED'))
    WHERE t.enabled          = TRUE
      AND t.schedule_ts     <= NOW()
      AND t.schedule_ts     < CURRENT_DATE + '1 Day'::INTERVAL
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
      -- Earlier process that has failed should be reprocessed first, assuming that gaps are not allowed
      AND NOT EXISTS (SELECT p.id
                        FROM logs.process p
                       WHERE p.task_id               = t.id
                         AND t.allow_gaps            = FALSE
                         AND p.status                = 'FAILURE'
                         AND p.reprocessed           = FALSE
                         AND p.ts_lower_bound        < t.ts_lower_bound)
      -- Don't pick up any task where the number of running instances is already up to max allowed
      AND (   t.max_running = 0
           OR t.max_running > (SELECT COUNT(p.id)
                                 FROM logs.process p
                                WHERE p.task_id          = t.id
                                  AND COALESCE(p.stage,'EXTRACT') = 'EXTRACT'
                                  AND p.status      NOT IN ('SUCCESS','FAILURE','KILLED')
                              )
          );

-- Need to implement a recursive query for the waits.
-- PostgreSQL 8.4 may implement WITH RECURSIVE, use it to implement the recursive query for the one below
-- have seen nested data for 5 levels.
-- better option would be to update the above query with the recursive option
CREATE OR REPLACE VIEW core.recursive_wait_v
    AS
  SELECT  DISTINCT
          t.id
         ,t.name
         ,'Waiting on a task that is waiting to be processed.'                           AS reason
         ,NULL::TIMESTAMP                                                                AS scheduled_at
         ,t.ts_start_with                                                                  AS ts_lower_bound
         ,wr.name                                                                        AS waiting_for
         ,t.process_mode
         ,t.slicing_mode
     FROM core.task           t
         ,core.chain          c
         ,core.wait_reasons_v wr
    WHERE t.enabled       = TRUE
      AND c.successor_id  = t.id
      AND c.enabled       = TRUE
      AND wr.id           = c.precursor_id;
