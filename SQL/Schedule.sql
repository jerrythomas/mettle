Time_Calendar
Business Hours : S 0, S 0, M-F 8am-5pm, Offset:1hr, (start time, interval)
Non business Hours: opp of Bus Hrs +offset,
Anytime : 24hrs

CREATE TABLE work



CREATE SEQUENCE schedule_id_seq
     START WITH 1
   INCREMENT BY 1;

CREATE TABLE schedule
(
   id                         INTEGER PRIMARY KEY DEFAULT NEXTVAL('schedule_id_seq')
  ,code                       VARCHAR(20)
  ,name                       VARCHAR(200) UNIQUE
  ,max_instances              INTEGER     default=1
  ,runs_per_day               INTEGER     default=1
  ,holiday_flag               char(1)     default 'N'
  ,eff_start_date             DATE
  ,eff_end_date               DATE
);

CREATE TABLE schedule_rules
(
   rule_id          NUMERIC(10)
  ,schedule_id      NUMERIC(10)  REFERENCES Schedule(Schedule_ID)
  ,runfrequency     VARCHAR(10) -- Daily/Weekly/Monthly/Quarterly/Yearly
  ,Months_to_run    varchar2(40);
  ,days_of_week     varchar2(14);
  ,
  ,runtype          VARCHAR(10) -- At/Between
  ,repeat
  ,repeatfrequency  VARCHAR(10) -- Daily/Weekly/Monthly/Quarterly/Yearly
  ,max_instances              INTEGER     default=1
  ,runs_per_day               INTEGER     default=1
  ,starttime        DATE
  ,endtime          DATE

);
drop table schedule_values;

CREATE SEQUENCE runnable_time_group_id_seq
     START WITH 1
   INCREMENT BY 1;

CREATE TABLE runnable_time_group
(
  id               INTEGER      PRIMARY KEY DEFAULT NEXTVAL('runnable_time_group_id_seq')
 ,code             VARCHAR(20)  UNIQUE
 ,name             VARCHAR(200) UNIQUE
 ,holiday_flag     varchar(1)   default = 'N'
 ,activated_on     TIMESTAMP    default = now();
 ,deactivated_on   TIMESTAMP
)

CREATE SEQUENCE runnable_time_id_seq
     START WITH 1
   INCREMENT BY 1;

CREATE TABLE runnable_time
(
  id                      INTEGER      PRIMARY KEY DEFAULT NEXTVAL('runnable_time_id_seq')
 ,runnable_time_group_id  INTEGER      REFERENCES runnable_time_group(ID)
 ,time_start              TIME         NOT NULL
 ,time_stop               TIME         NOT NULL
 ,duration                INTERVAL     DEFAULT ='8hrs'
 ,offset_buffer_ts        INTERVAL     DEFAULT ='1hrs'
 ,day_of_week             INTEGER
 ,special_date            date
 ,use_time_zones          INTEGER
 ,time_zone               INTERVAL
);


CREATE TABLE schedule_days
(
   detail_id        NUMERIC(10)
  ,schedule_id      NUMERIC(10)  -- REFERENCES Schedule(Schedule_ID)
  ,frequency        VARCHAR(10) -- Daily/Weekly/Monthly/Quarterly/Yearly
  ,day_of_week      INTEGER
  ,month_nbr        INTEGER
  ,day_of_month     INTEGER
  ,run_strt_ts      time
  ,run_stop_ts      time
);

create view active_schedule_v
as
select s.name
      ,sv.weekday
      ,sv.month_nbr
      ,sv.run_on_day_nbr
      ,sv.run_strt_ts
      ,sv.run_stop_ts
  from schedule            s
      ,schedule_days       sv
      ,runnable_time_group rtg
      ,runnable_time       rt
 where sv.schedule_id            = s.id
   and rtg.schedule_id           = s.id
   and rt.runnable_time_group_id = rtg.id
   and ( (    rt.day_of_week       = extract(dow from now())
          and CURRENT_TIME   between rt.time_start
                                 and rt.time_stop)
       OR EXISTS (SELECT rtg.schedule_id
                    FROM runnable_time_group rtg_h
                        ,runnable_time       rt_h
                   where rtg_h.schedule_id           = s.id
                     and rt_h.runnable_time_group_id = rtg_h.id
                     and rt.special_date = CURRENT_DATE)
       )
   and coalesce(sv.day_of_week  ,extract(dow   from now())) = extract(dow   from now())
   and coalesce(sv.month_nbr,extract(month from now()))     = extract(month from now())
   and CURRENT_TIME between sv.run_strt_ts
                        and sv.run_stop_ts
   and



insert into schedule
values (NEXTVAL('schedule_id_seq'),'ANYTIME','Run any time during the day',1,1,'N',now(),null);
insert into schedule
values (NEXTVAL('schedule_id_seq'),'NON-WRK-HRS','Non Working Hours',1,1,'N',now(),null);
insert into schedule
values (NEXTVAL('schedule_id_seq'),'WRK-HRS','Working Hours',1,1,'N',now(),null);
insert into schedule
values (NEXTVAL('schedule_id_seq'),'HOLIDAY','Holidays',1,1,'Y',now(),null);

insert into runnable_time
values(NEXTVAL('runnable_time_id_seq'),Select id from schedule where code = 'ANYTIME',null,null,null,'00:00:00.00','23:59:59.99'); -- Sunday

insert into schedule_values
values( 1,1,'Daily',0,null,null,'00:00:00.00','23:59:59.99'); -- Sunday
insert into schedule_values
values( 2,1,'Daily',1,null,null,'00:00:00.00','05:59:59.99');
insert into schedule_values
values( 3,1,'Daily',1,null,null,'20:00:00.00','23:59:59.99');
insert into schedule_values
values( 4,1,'Daily',2,null,null,'00:00:00.00','05:59:59.99');
insert into schedule_values
values( 5,1,'Daily',2,null,null,'20:00:00.00','23:59:59.99');
insert into schedule_values
values( 6,1,'Daily',3,null,null,'00:00:00.00','05:59:59.99');
insert into schedule_values
values( 7,1,'Daily',3,null,null,'20:00:00.00','23:59:59.99');
insert into schedule_values
values( 8,1,'Daily',4,null,null,'00:00:00.00','05:59:59.99');
insert into schedule_values
values( 9,1,'Daily',4,null,null,'20:00:00.00','23:59:59.99');
insert into schedule_values
values(10,1,'Daily',5,null,null,'00:00:00.00','05:59:59.99');
insert into schedule_values
values(11,1,'Daily',5,null,null,'20:00:00.00','23:59:59.99');
insert into schedule_values
values(12,1,'Daily',6,null,null,'00:00:00.00','23:59:59.99'); -- Saturday



nth day of month repeat n days
nth day of quarter
nth day of year

nth [weekday] of [month,quarter,year]

extract (day from now()) -- Day of month
date(       extract(year  from now())
     ||'-'||extract(month from now())
     ||'-'||sv.run_on_day_nbr)  = current_date



Month - [1,4,7,10] or [1,2,3,4,5,6,7,8,9,10,11,12]
Week  - [0,1,2,3,4,5,6]
Day   - [n,R-N,S-m]  n=[0-31] 0 => last day, R => repeat, S => skip





