-- Alternate view for the timed tasks. This executes in 67 ms v/s the old one which runs for more that 5 seconds
-- need to verify what happens when the number of rows in the process log grows to a large value say 5 million records.
-- Log archive process can help in limiting the rows in the active table, however a larger volume 
-- will still be a bottleneck
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
  LEFT OUTER JOIN core.process_counts_v pcv
               ON pcv.task_id = t.id
 WHERE t.enabled       = TRUE
   AND (t.max_running = 0 
        OR coalesce(pcv.running_count,0) < t.max_running)
   AND coalesce(pcv.precursor_failed_count,0) = 0
   AND coalesce(pcv.conflict_running,0) = 0 


create view core.process_counts_v
as
 SELECT p.task_id
       ,count(*)  as total_runs
       ,count(distinct c.id) as chain_count
       ,SUM(CASE WHEN p.completed_at IS NULL THEN 1 ELSE 0 END) AS running_count
       ,SUM(CASE WHEN c.kind = 'CASCADE'  
                  AND COALESCE(px.status,'x') ~* c.precursor_status THEN 1 ELSE 0 END) as precursor_ran_count
       ,SUM(CASE WHEN c.kind = 'CASCADE'  
                  AND COALESCE(px.status,'x') !~* c.precursor_status THEN 1 ELSE 0 END) as precursor_failed_count
       ,SUM(CASE WHEN c.kind = 'CONFLICT' 
                  AND COALESCE(px.status,'x') ~* c.precursor_status 
                  AND px.id IS NOT NULL THEN 1 ELSE 0 END) as conflict_running
  FROM logs.process p
   LEFT OUTER JOIN core.chain c
                ON p.task_id  = c.successor_id
               --AND c.kind     = 'CONFLICT'
               AND c.enabled  = TRUE
   LEFT OUTER JOIN logs.process px            
                ON px.task_id     = c.precursor_id
               AND px.reprocessed = FALSE
               --AND px.status       <> coalesce(c.precursor_status,px.status) -- 'Successful','Failed','Killed')
 group by p.task_id   
 -- potentioal alternative is to embed the logic of process_counts_v into this query and use 
 -- HAVING as below. This takes 82ms now.
 
 
 
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
      ,SUM(prv.cascade_running) 
      ,SUM(prv.conflict_running)
  FROM core.tasks_timed_v  t
  LEFT OUTER JOIN core.precursor_run_v prv
               ON prv.successor_id = t.id    
GROUP BY t.id
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
HAVING SUM(COALESCE(prv.cascade_running ,0)) = 0
   AND SUM(COALESCE(prv.conflict_running,0)) = 0    
   
   
CREATE OR REPLACE VIEW core.runnable_alt2_v
AS
SELECT t.id                                                   AS id
      ,t.name                                                 AS name
      ,t.executable
      ,t.slicing_mode
      ,t.logging_mode
      ,t.process_mode
      ,t.dynamic_split
      ,asv.schedule_ts + t.process_offset                     AS schedule_ts
      ,(CASE WHEN t.process_mode = 'TIMED'
             THEN asv.schedule_ts
             ELSE t.ts_start_with END)                        AS ts_lower_bound
      ,(CASE WHEN t.process_mode = 'TIMED'
             THEN asv.schedule_ts + t.ts_increment_by 
             ELSE LEAST((CASE WHEN (t.ts_increment_by = '00:00:00'::INTERVAL) THEN
                                 CURRENT_DATE + t.process_offset
                              ELSE
                                 t.ts_start_with + t.ts_increment_by
                              END)
                       ,CURRENT_DATE + t.process_offset)
                                END)                          AS ts_upper_bound
      ,NULL::NUMERIC                                          AS ns_lower_bound
      ,NULL::NUMERIC                                          AS ns_upper_bound
      ,t.max_retries
      ,t.max_running
      ,t.process_rowlimit
      ,t.hold_applied
      ,t.ts_start_with
      ,t.allow_gaps
      ,t.allow_parallel_load
      ,t.process_offset
      ,t.currently_running
      ,t.awaiting_reprocess
      ,NULL::NUMERIC                AS old_process_id
  FROM core.task                t
       INNER JOIN core.auto_schedule_v   asv
               ON t.schedule_id = asv.id
              AND asv.date      = t.ts_start_with -  asv.time_of_day
 WHERE (   t.max_running = 0
        OR t.max_running > t.currently_running)
   AND t.slicing_mode    = 'TIME'
   AND t.process_mode   IN ('TIMED','AUTO')
   AND NOT EXISTS (SELECT prv.precursor_id
                     FROM core.precursor_run_v prv
                    WHERE prv.successor_id = t.id
                      AND (   prv.cascade_running = 1 
                           OR prv.conflict_running = 1))
UNION ALL
SELECT t.id
      ,t.name
      ,t.executable
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
      ,t.process_rowlimit
      ,t.hold_applied
      ,t.ts_start_with
      ,t.allow_gaps
      ,t.allow_parallel_load
      ,t.process_offset
      ,t.currently_running
      ,t.awaiting_reprocess
      ,COALESCE(p.original_process_id,p.id)                        AS old_process_id
  FROM logs.process        p
       INNER JOIN core.task           t
               ON t.id             = p.task_id
              AND p.completed_at  <= NOW() - t.retry_interval
              AND p.status        IN ('Failed','Crashed','Killed')
              AND p.reprocessed    = FALSE
       INNER JOIN core.auto_schedule_v   asv
               ON asv.id           = t.schedule_id    
              AND asv.date         = t.ts_start_with -  asv.time_of_day
 WHERE (   t.max_running = 0
        OR t.max_running > t.currently_running)
   AND NOT EXISTS (SELECT prv.precursor_id
                     FROM core.precursor_run_v prv
                    WHERE prv.successor_id = t.id
                       AND (   prv.cascade_running = 1 
                            OR prv.conflict_running = 1))
   
-- One more Alternative     
-- Eliminates most sub views, avoids the calendar table, (not sure if that is a good thing)
-- runs in 119 ms 

CREATE OR REPLACE VIEW core.runnable_alt_v
AS              
  SELECT t.id
        ,t.name
        ,t.slicing_mode
        ,t.logging_mode
        ,t.process_mode
        ,t.dynamic_split 
        ,MIN(t.ts_start_with + process_offset + tt.time_of_day)    schedule_ts
        ,MIN(t.ts_start_with + tt.time_of_day)                                   AS ts_lower_bound
        ,MIN(CASE WHEN t.ts_increment_by = '00:00:00'::interval
                  THEN NOW()
                  ELSE t.ts_start_with + tt.time_of_day + t.ts_increment_by 
              END)                                                               AS ts_upper_bound  
        ,NULL as ns_lower_bound
        ,NULL as ns_upper_bound                       
        ,t.max_retries
        ,t.max_running
        ,t.process_rowlimit
        ,t.hold_applied
        ,t.ts_start_with
        ,NULL::NUMERIC                AS old_process_id   
    FROM core.task t
         INNER JOIN core.schedule s
                 ON s.id              = t.schedule_id
         INNER JOIN core.timetable tt
                 ON tt.schedule_id    = s.id
                AND tt.is_restriction = FALSE
         LEFT OUTER JOIN core.precursor_run_v prv
                 ON prv.successor_id = t.id 
                AND (   (    t.process_mode   = 'TIMED'
                         AND t.ts_start_with + tt.time_of_day = prv.ts_lower_bound)
                     OR (    t.process_mode   = 'AUTO'
                         AND t.ts_start_with + tt.time_of_day >= prv.ts_lower_bound)
                    )         
   WHERE tt.run_strt_ts  <= CURRENT_TIME
     AND tt.run_stop_ts  >= CURRENT_TIME
     AND COALESCE(tt.day_of_week,EXTRACT(dow FROM CURRENT_DATE))   = EXTRACT(dow   FROM CURRENT_DATE)
     AND COALESCE(tt.month      ,EXTRACT(month FROM CURRENT_DATE)) = EXTRACT(month FROM CURRENT_DATE) 
     --AND COALESCE(tt.week,EXTRACT(week FROM CURRENT_DATE)) = EXTRACT(week FROM CURRENT_DATE) 
     AND core.DayOf(CURRENT_DATE,tt.day_of_month)                  = EXTRACT(day from CURRENT_DATE)
     --AND tt.time_of_day <= NOW() - CURRENT_DATE
     AND t.ts_start_with + t.process_offset + tt.time_of_day <= NOW() 
     AND (   t.max_running = 0
          OR t.max_running > t.currently_running)                     
     AND NOT EXISTS (SELECT 1
                       FROM core.timetable   ttx
                      WHERE ttx.schedule_id = s.id
                        AND ttx.is_restriction = TRUE
                        AND COALESCE(ttx.day_of_week,EXTRACT(DOW FROM NOW())) = EXTRACT(DOW FROM NOW())
                        AND CURRENT_TIME   BETWEEN ttx.run_strt_ts
                                               AND ttx.run_stop_ts) 
GROUP BY t.id
        ,t.name
        ,t.slicing_mode
        ,t.logging_mode
        ,t.process_mode
        ,t.dynamic_split 
        ,t.max_retries
        ,t.max_running
        ,t.process_rowlimit
        ,t.hold_applied
        ,t.ts_start_with
  HAVING SUM(COALESCE(prv.cascade_running,0)) = 0
     AND SUM(COALESCE(prv.conflict_running,0)) = 0
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
      ,t.process_rowlimit
      ,t.hold_applied
      ,t.ts_start_with
      ,COALESCE(p.original_process_id,p.id)                        AS old_process_id
  FROM logs.process        p
       INNER JOIN core.task           t
               ON t.id             = p.task_id
              AND p.completed_at  <= NOW() - t.retry_interval
         INNER JOIN core.schedule s
                 ON s.id              = t.schedule_id
         INNER JOIN core.timetable tt
                 ON tt.schedule_id    = s.id
                AND tt.is_restriction = FALSE
         LEFT OUTER JOIN core.precursor_run_v prv
                 ON prv.successor_id = t.id 
                AND (   (    t.process_mode   = 'TIMED'
                         AND t.ts_start_with + tt.time_of_day = prv.ts_lower_bound)
                     OR (    t.process_mode   = 'AUTO'
                         AND t.ts_start_with + tt.time_of_day >= prv.ts_lower_bound)
                    )         
 WHERE p.status         = 'Failed'
   AND p.reprocessed    = FALSE
   AND tt.run_strt_ts  <= CURRENT_TIME
   AND tt.run_stop_ts  >= CURRENT_TIME
   AND COALESCE(tt.day_of_week,EXTRACT(dow FROM CURRENT_DATE))   = EXTRACT(dow   FROM CURRENT_DATE)
   AND COALESCE(tt.month      ,EXTRACT(month FROM CURRENT_DATE)) = EXTRACT(month FROM CURRENT_DATE) 
   --AND COALESCE(tt.week,EXTRACT(week FROM CURRENT_DATE)) = EXTRACT(week FROM CURRENT_DATE) 
   AND core.DayOf(CURRENT_DATE,tt.day_of_month)                  = EXTRACT(day from CURRENT_DATE)
   AND (   t.max_running = 0
        OR t.max_running > t.currently_running)                     
   AND NOT EXISTS (SELECT 1
                     FROM core.timetable   ttx
                    WHERE ttx.schedule_id = s.id
                      AND ttx.is_restriction = TRUE
                      AND COALESCE(ttx.day_of_week,EXTRACT(DOW FROM NOW())) = EXTRACT(DOW FROM NOW())
                      AND CURRENT_TIME   BETWEEN ttx.run_strt_ts
                                             AND ttx.run_stop_ts)  