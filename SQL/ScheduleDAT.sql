delete from core.timetable;
delete from core.schedule;

-- Anytime
INSERT INTO core.schedule
VALUES (NEXTVAL('core.schedule_id_sq'),null,'any time',1,1,now(),null);

INSERT INTO core.timetable(id,schedule_id,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'00:00:00.00','23:59:59.99');

-- Non working hours Daily
INSERT INTO core.schedule
VALUES (NEXTVAL('core.schedule_id_sq'),null,'before 6 am and after 8 pm on weekdays and any time during weekends',1,1,now(),null);

INSERT INTO core.timetable(id,schedule_id,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,day_of_week,run_strt_ts,run_stop_ts,is_restriction)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),1,'08:00:00.00','18:00:00.00',true);
INSERT INTO core.timetable(id,schedule_id,day_of_week,run_strt_ts,run_stop_ts,is_restriction)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),2,'08:00:00.00','18:00:00.00',true);
INSERT INTO core.timetable(id,schedule_id,day_of_week,run_strt_ts,run_stop_ts,is_restriction)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),3,'08:00:00.00','18:00:00.00',true);
INSERT INTO core.timetable(id,schedule_id,day_of_week,run_strt_ts,run_stop_ts,is_restriction)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),4,'08:00:00.00','18:00:00.00',true);
INSERT INTO core.timetable(id,schedule_id,day_of_week,run_strt_ts,run_stop_ts,is_restriction)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),5,'08:00:00.00','18:00:00.00',true);


--Working hours
INSERT INTO core.schedule
VALUES (NEXTVAL('core.schedule_id_sq'),null,'between 8am and 6 pm on weekdays',1,1,now(),null);
INSERT INTO core.timetable(id,schedule_id,day_of_week,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),1,'08:00:00.00','18:00:00.00');
INSERT INTO core.timetable(id,schedule_id,day_of_week,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),2,'08:00:00.00','18:00:00.00');
INSERT INTO core.timetable(id,schedule_id,day_of_week,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),3,'08:00:00.00','18:00:00.00');
INSERT INTO core.timetable(id,schedule_id,day_of_week,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),4,'08:00:00.00','18:00:00.00');
INSERT INTO core.timetable(id,schedule_id,day_of_week,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),5,'08:00:00.00','18:00:00.00');

-- First Day of every Month
INSERT INTO core.schedule
VALUES (NEXTVAL('core.schedule_id_sq'),null,'On the first day of every month',1,1,now(),null);
INSERT INTO core.timetable(id,schedule_id,day_of_month,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),1,'00:00:00.00','23:59:59.99');

-- every 10 minutes
INSERT INTO core.schedule
VALUES (NEXTVAL('core.schedule_id_sq'),null,'every 10 minutes between 8am and 9 am',1,1,now(),null);
INSERT INTO core.timetable(id,schedule_id,time_of_day)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'08:00:00.00');
INSERT INTO core.timetable(id,schedule_id,time_of_day)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'08:10:00.00');
INSERT INTO core.timetable(id,schedule_id,time_of_day)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'08:20:00.00');
INSERT INTO core.timetable(id,schedule_id,time_of_day)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'08:30:00.00');
INSERT INTO core.timetable(id,schedule_id,time_of_day)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'08:40:00.00');
INSERT INTO core.timetable(id,schedule_id,time_of_day)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'08:50:00.00');
INSERT INTO core.timetable(id,schedule_id,time_of_day)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'09:00:00.00');

-- every hour
INSERT INTO core.schedule
VALUES (NEXTVAL('core.schedule_id_sq'),null,'every hour',1,1,now(),null);
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'00:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'01:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'02:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'03:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'04:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'05:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'06:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'07:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'08:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'09:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'10:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'11:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'12:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'13:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'14:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'15:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'16:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'17:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'18:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'19:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'20:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'21:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'22:00:00.00','00:00:00.00','23:59:59.99');
INSERT INTO core.timetable(id,schedule_id,time_of_day,run_strt_ts,run_stop_ts)
VALUES(NEXTVAL('core.timetable_id_sq'),CURRVAL('core.schedule_id_sq'),'23:00:00.00','00:00:00.00','23:59:59.99');


-- Christmas holidays
--INSERT INTO core.schedule
--VALUES (NEXTVAL('core.schedule_id_sq'),null,'From 25 Dec 2009 to 26 Dec 2009',1,1,'Y',now(),null);

select core.load_calendar(to_date('01-JAN-2009','DD-MON-YYYY'),5);