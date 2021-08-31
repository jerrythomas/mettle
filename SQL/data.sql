select * from core.runnable_v


select * from logs.process where id = 560

select * from logs.process where os_pid = 44809
select * from logs.stage where process_id = 589

select * from logs.activity where duration > '00:00:01'::interval

delete from logs.activity;
delete from logs.stage;
delete from logs.process;

update core.task set ts_start_with = '2009-01-01';
update core.task
   set ts_start_with = now()
      --,ts_increment_by = '1 month'
where name like '%Summary%';