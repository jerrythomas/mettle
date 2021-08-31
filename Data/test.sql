--test.sql
update core.task set slice_last_run = '2009-05-27';
insert into logs.process(task_id,status_code,scheduled_at,slicing_mode,ts_lower_bound,ts_upper_bound)
select id,'INITIATED',schedule_ts,slicing_mode,ts_lower_bound,ts_upper_bound from core.runnable_v

update core.task t
   set slice_last_run = (select (case when t.process_mode = 'AUTO' THEN
                                    p.ts_upper_bound
                                    else p.ts_upper_bound - t.process_offset end)
                                     from logs.process  p where task_id = t.id and p.status_code = 'INITIATED')
 where t.id in (select p.task_id from logs.process  p where p.status_code = 'INITIATED')


select core.initiate()

delete from logs.process;
update core.task set ts_start_with = '2009-01-01';
update core.task set ts_increment_by = null where ts_increment_by = '00:00:00';
--update core.task set ts_start_with = '2009-01-01' where name like '%Summary%';

update core.chain c
   set enabled = false
 from core.task t
      ,core.task p
 where c.precursor_id = p.id
   and c.successor_id = t.id
   and t.process_mode = 'AUTO'
   and substr(t.name,length(t.name) -3) <>  substr(p.name,length(p.name) -3) ;

select * from core.task where name like '%Transa%'

select *  from logs.process where task_id = 322
update logs.process set status_code = 'SUCCESS'
update core.task
   set ts_start_with = '2009-01-01'
      ,ts_increment_by = '1 month'
where name like '%Summary%'

select * from logs.process where task_id in (
select t.id --,t.name,c.kind,c.enabled
from core.chain c, core.task t  where t.id = c.precursor_id and c.successor_id = 700)


select * from core.runnable_v where id in (700,715,683,725)

select * from core.task where id = 158

select max(p.ts_lower_bound),max(p.ts_upper_bound), t.name
  from logs.process p
      ,core.task t
  where t.id = p.task_id and p.task_id in (
select precursor_id from core.chain where successor_id = 683)
group by t.name

select * from core.task where id = 159

