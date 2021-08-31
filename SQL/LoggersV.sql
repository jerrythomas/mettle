--LoggersV.sql
CREATE OR REPLACE VIEW logs.process_stats_v
AS
SELECT p.id
      ,t.name
      ,p.os_pid
      ,p.status
      ,p.stage
      ,p.initiated_at
      ,p.completed_at
      ,p.wait_duration
      ,p.run_duration
      ,p.rows_extracted
      ,p.rows_loaded
      ,p.rows_transformed
      ,p.rows_rejected
      ,p.rows_with_dangling_keys
      ,p.slicing_mode
      ,p.ts_lower_bound
      ,p.ts_upper_bound
      --,p.ns_lower_bound
      --,p.ns_upper_bound
      ,p.server
      ,p.error_file
      ,p.trace_file
      ,p.reprocessed
      ,p.original_process_id
      ,p.user_id
      ,p.submitted_on
      ,p.pattern_match      as file_name
  FROM logs.process        p
      ,core.task           t
 WHERE t.id         = p.task_id    ;
