-- $Header Schedule.sql 0.01 11-Dec-2007 Jerry
/*
 * File Name  : Schedule.sql
 * Purpose    : Store the schedules.
 * Author     : Jerry Thomas
 * Version    : 0.01
 * Created On : 11-Dec-2007
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 */

SET search_path        TO core,public;
SET default_tablespace = cf_core_dat;


CREATE SEQUENCE calendar_id_sq
     START WITH 1
   INCREMENT BY 1;

CREATE TABLE calendar
(
   id                       NUMERIC(10)    PRIMARY KEY DEFAULT NEXTVAL('calendar_id_sq')
  ,date                     DATE
  ,year                     INTEGER
  ,quarter                  INTEGER
  ,month                    INTEGER
  ,day                      INTEGER
  ,dow                      INTEGER
  ,is_holiday               BOOLEAN        DEFAULT FALSE
  ,is_weekend               BOOLEAN        DEFAULT FALSE
  ,notes                    VARCHAR(200)
);
-- should holidays and weekends be identified by region?
-- if so how will it impact the schedules?

ALTER INDEX calendar_pkey
        SET TABLESPACE cf_core_idx;

CREATE UNIQUE INDEX calendar_date_key
                 ON core.calendar(date);
ALTER INDEX core.calendar_date_key
        SET TABLESPACE cf_core_idx;


CREATE SEQUENCE schedule_id_sq
     START WITH 1
   INCREMENT BY 1;

CREATE TABLE schedule
(
   id                       NUMERIC(10)     PRIMARY KEY DEFAULT NEXTVAL('schedule_id_sq')
  ,icon                     VARCHAR(200)
  ,rule                     VARCHAR(2000)   UNIQUE
  ,max_instances            INTEGER         DEFAULT 1
  ,runs_per_day             INTEGER         DEFAULT 1
  ,eff_start_date           TIMESTAMP
  ,eff_end_date             TIMESTAMP
  ,modified_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER INDEX schedule_pkey
        SET TABLESPACE cf_core_idx;
ALTER INDEX schedule_rule_key
        SET TABLESPACE cf_core_idx;

CREATE SEQUENCE repetition_id_sq
     START WITH 1
   INCREMENT BY 1;

CREATE TABLE repetition
(
   id                       NUMERIC(10)     PRIMARY KEY DEFAULT NEXTVAL('repetition_id_sq')
  ,schedule_id              NUMERIC(10)
  ,schedule_offset          INTERVAL        DEFAULT '7 Days'
  ,eff_start_date           TIMESTAMP
  ,eff_end_date             TIMESTAMP
  ,modified_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER INDEX repetition_pkey
        SET TABLESPACE cf_core_idx;
ALTER TABLE repetition
        ADD CONSTRAINT repetition_fkey
               FOREIGN KEY (schedule_id)
            REFERENCES schedule (id);

CREATE INDEX repetition_fkey
          ON repetition(schedule_id)
  TABLESPACE cf_core_idx;

CREATE SEQUENCE timetable_id_sq
     START WITH 1
   INCREMENT BY 1;

CREATE TABLE timetable
(
   id                       NUMERIC(10)     PRIMARY KEY DEFAULT NEXTVAL('timetable_id_sq')
  ,schedule_id              NUMERIC(10)
  ,is_restriction           BOOLEAN         DEFAULT FALSE
  ,week                     INTEGER
  ,month                    INTEGER
  ,time_of_day              TIME            DEFAULT '00:00:00.00'
  ,day_of_week              INTEGER
  ,day_of_month             INTEGER
  ,run_strt_ts              TIME            DEFAULT '00:00:00.00'
  ,run_stop_ts              TIME            DEFAULT '23:59:59.99'
  ,modified_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER INDEX timetable_pkey SET TABLESPACE cf_core_idx;

ALTER TABLE timetable
        ADD CONSTRAINT timetable_fkey
               FOREIGN KEY (schedule_id)
            REFERENCES schedule (id);

CREATE INDEX timetable_fkey
          ON timetable(schedule_id)
  TABLESPACE cf_core_idx;


/*


CREATE SEQUENCE sked_granular_id_sq
     START WITH 1
   INCREMENT BY 1;

CREATE TABLE sked_granular
(
   id               NUMERIC(10)    PRIMARY KEY DEFAULT NEXTVAL ('sked_granular_id_sq')
  ,schedule_id      INTEGER
  ,runfrequency     VARCHAR(10) -- Daily/Weekly/Monthly/Quarterly/Yearly
  ,Months_to_run    VARCHAR(40)
  ,days_of_week     VARCHAR(14)
  ,runtype          VARCHAR(10) -- At/Between
  ,repeat           NUMERIC(10)
  ,repeatfrequency  VARCHAR(10) -- Daily/Weekly/Monthly/Quarterly/Yearly
  ,starttime        TIMESTAMP
  ,endtime          TIMESTAMP
);

ALTER INDEX sked_granular_pkey SET TABLESPACE cf_core_idx;

ALTER TABLE sked_granular
        ADD CONSTRAINT sked_granular_fkey
               FOREIGN KEY (schedule_id)
            REFERENCES schedule (id);

CREATE INDEX sked_granular_fkey
          ON sked_granular(schedule_id)
  TABLESPACE cf_core_idx;
*/