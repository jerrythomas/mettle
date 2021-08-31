
--Views
DROP VIEW IF EXISTS logs.process_stats_v;
DROP VIEW IF EXISTS core.recursive_wait_v;
DROP VIEW IF EXISTS core.wait_reasons_v;

DROP VIEW IF EXISTS core.triggered_v;
DROP VIEW IF EXISTS core.runnable_v;
DROP VIEW IF EXISTS core.auto_precursor_runs_v;
DROP VIEW IF EXISTS core.tasks_timed_v;
DROP VIEW IF EXISTS core.tasks_auto_v;

DROP VIEW IF EXISTS core.auto_schedule_v;
DROP VIEW IF EXISTS core.timed_schedule_v;
DROP VIEW IF EXISTS core.active_schedule_v;

--Functions
DROP FUNCTION IF EXISTS core.initiate(file_name VARCHAR);
DROP FUNCTION IF EXISTS core.initiate();
DROP FUNCTION IF EXISTS core.DayOfThisMonth(dayof  DOUBLE PRECISION);
DROP FUNCTION IF EXISTS core.DayOf(xtr_dt DATE,dayof  INTEGER);

--Tables
DROP TABLE IF EXISTS logs.clients ;
DROP TABLE IF EXISTS logs.errors  ;
DROP TABLE IF EXISTS logs.activity;
DROP TABLE IF EXISTS logs.stage   ;
DROP TABLE IF EXISTS logs.process cascade;

DROP SEQUENCE IF EXISTS logs.process_id_sq cascade;
DROP SEQUENCE IF EXISTS logs.stage_id_sq   ;
DROP SEQUENCE IF EXISTS logs.activity_id_sq;
DROP SEQUENCE IF EXISTS logs.error_id_sq  ;
DROP SEQUENCE IF EXISTS logs.client_id_sq ;

DROP TABLE IF EXISTS core.chain;
DROP TABLE IF EXISTS core.task cascade;
DROP TABLE IF EXISTS core.timetable;
DROP TABLE IF EXISTS core.repetition;
DROP TABLE IF EXISTS core.schedule;
DROP TABLE IF EXISTS core.calendar;

--Sequences
DROP SEQUENCE IF EXISTS core.chain_id_sq;
DROP SEQUENCE IF EXISTS core.task_id_sq;
DROP SEQUENCE IF EXISTS core.calendar_id_sq;
DROP SEQUENCE IF EXISTS core.repetition_id_sq;
DROP SEQUENCE IF EXISTS core.schedule_id_sq;
DROP SEQUENCE IF EXISTS core.timetable_id_sq;