CREATE OR REPLACE FUNCTION core.last_day(date)
RETURNS date AS
$$
  SELECT (date_trunc('MONTH', $1) + INTERVAL '1 MONTH - 1 day')::date;
$$ LANGUAGE 'sql' IMMUTABLE STRICT;

-- Extracts and provides the nth day of the current month. If no value provided returns current day
CREATE OR REPLACE FUNCTION core.DayOfThisMonth(dayof  DOUBLE PRECISION)
RETURNS INTEGER AS $$
DECLARE
   dy   INTEGER;
   ldy  INTEGER;
   
BEGIN

   IF dayof IS NULL THEN
      RETURN EXTRACT(DAY FROM NOW());
   END IF;
   ldy := extract(DAY FROM (date_trunc('month', now()) + INTERVAL '1 month - 1 day'));

   IF dayof = 0 THEN
     dy:= ldy;
   ELSIF dayof < 0 THEN
     dy:= extract(DAY FROM (date_trunc('month', now()) + INTERVAL '1 month' + (dayof||' days')::INTERVAL));
   --ELSIF dayof < ldy THEN
   --  dy := dayof;
   ELSE
     dy := LEAST(dayof,ldy);
   END IF;

   RETURN dy;
EXCEPTION
   WHEN OTHERS THEN
      RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Extracts and provides the nth day of the month. If N is empty return current day
CREATE OR REPLACE FUNCTION core.DayOf(xtr_dt DATE
                                     ,dayof  INTEGER)
RETURNS INTEGER AS $$
DECLARE
   dy   INTEGER;
   ldy  INTEGER;
BEGIN

   IF dayof IS NULL THEN
      --RETURN NULL;
      RETURN EXTRACT(DAY FROM xtr_dt);
   END IF;
   ldy := extract(DAY FROM (date_trunc('month', xtr_dt) + INTERVAL '1 month - 1 day'));

   IF dayof = 0 THEN
     dy:= ldy;
   ELSIF dayof < 0 THEN
     dy:= extract(DAY FROM (date_trunc('month', xtr_dt) + INTERVAL '1 month + '|| dayof ||' days'));
   --ELSIF dayof < ldy THEN
   --  dy := dayof;
   ELSE
     dy := LEAST(dayof,ldy);
   END IF;

   RETURN dy;
EXCEPTION
   WHEN OTHERS THEN
      RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION core.last_of_month (in_ts TIMESTAMP
                                              ,n     INTEGER
                                              ,typ   VARCHAR)
RETURNS TIMESTAMP AS $$
DECLARE
   dy   INTEGER;
BEGIN
   IF (typ =='DAY') THEN
       SELECT date_trunc('month', current_date + '1 month'::INTERVAL) - '1 day'::INTERVAL;
   ELSIF (Typ == 'DOW') THEN
       SELECT date_trunc('month', current_date + '1 month'::INTERVAL) - '1 day'::INTERVAL +
              (((n - 7 - TO_CHAR(date_trunc('month', current_date + '1 month'::INTERVAL) -
                '1 day'::INTERVAL,'D')::int) %7)||' days')::INTERVAL;
   END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION core.update_calendar()
RETURNS TRIGGER AS $cal_trigger$
DECLARE
BEGIN
   UPDATE core.calendar c
      SET year   = EXTRACT(YEAR FROM NEW.date)
         ,month  = EXTRACT(MONTH FROM NEW.date)
         ,day    = EXTRACT(DAY FROM NEW.date)
         ,dow    = EXTRACT(DOW FROM NEW.date)
    WHERE date   = NEW.date;
RETURN NEW;
END;
$cal_trigger$ LANGUAGE plpgsql;

CREATE TRIGGER cal_trigger AFTER INSERT ON core.calendar
                             FOR EACH ROW
                         EXECUTE PROCEDURE core.update_calendar() ;


CREATE OR REPLACE FUNCTION core.load_calendar(strt_dt DATE
                                              ,years   INTEGER)
RETURNS BOOLEAN
AS $$
DECLARE
   end_dt   DATE;
   cal_dt   DATE;
BEGIN
   end_dt = strt_dt + (years||' years')::interval;
   cal_dt = strt_dt;

   WHILE cal_dt < end_dt
   LOOP
      BEGIN
         INSERT INTO core.calendar(date) values (cal_dt);
      EXCEPTION
         WHEN unique_violation THEN
             NULL;
      END;
      cal_dt = cal_dt + '1 day'::interval;
   END LOOP;
   RETURN TRUE;
EXCEPTION
   WHEN OTHERS THEN
      RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION core.initiate(file_name VARCHAR)
RETURNS BOOLEAN
AS $$
BEGIN
   INSERT INTO logs.process(task_id
                           ,status_code
                           ,scheduled_at
                           ,slicing_mode
                           ,ts_lower_bound
                           ,ts_upper_bound
                           ,pattern_match)
        SELECT id
              ,'Initiated'
              ,NOW()
              ,'TRIGGER'
              ,TO_DATE(regexp_replace(file_name
                                     ,t.pattern_match
                                     ,t.pattern_date
                                     ,'i'),t.date_format)
                 +regexp_replace(file_name
                                ,t.pattern_match
                                ,t.pattern_interval
                                ,'i')::interval           as ts_lower_bound
              ,TO_DATE(regexp_replace(file_name
                                              ,t.pattern_match
                                              ,t.pattern_date
                                              ,'i'),t.date_format)
                          +regexp_replace(file_name
                                         ,t.pattern_match
                                         ,t.pattern_interval
                                ,'i')::interval
                          +t.slice_value                  as ts_upper_bound
              ,file_name
          FROM core.triggered_v t
         WHERE t.pattern_match ~* file_name;

   RETURN TRUE;
EXCEPTION
   WHEN OTHERS THEN
      RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION core.initiate()
RETURNS NUMERIC
AS $$
DECLARE
   num_rows  numeric := 0;
BEGIN
   INSERT INTO logs.process(task_id
                           ,status
                           ,scheduled_at
                           ,slicing_mode
                           ,ts_lower_bound
                           ,ts_upper_bound
                           ,original_process_id)
        SELECT id
              ,'Initiated'
              ,schedule_ts
              ,slicing_mode
              ,ts_lower_bound
              ,ts_upper_bound
              ,original_process_id
         FROM core.runnable_v;

   GET DIAGNOSTICS num_rows = ROW_COUNT;

   UPDATE core.task t
      SET ts_start_with = p.ts_upper_bound
     FROM logs.process p
    WHERE p.task_id     = t.id
      AND p.status      = 'Initiated';

   RETURN num_rows;
EXCEPTION
   WHEN OTHERS THEN
      RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- initiate a manual submission of a task with the optional argument expressions to be used
-- in_expression may be a collection of the optional parameters and the values to be used.
-- may need a redesign for optimal usage & functionality
CREATE OR REPLACE FUNCTION core.initiate(in_task_id        NUMERIC
                                        ,in_expression     TEXT
                                        ,in_ts_lower_bound TIMESTAMP
                                        ,in_ts_upper_bound TIMESTAMP)
RETURNS NUMERIC
AS $$
DECLARE
   num_rows  numeric := 0;
BEGIN
   INSERT INTO logs.process(task_id
                           ,status
                           ,scheduled_at
                           ,slicing_mode
                           ,process_mode
                           ,expression
                           ,ts_lower_bound
                           ,ts_upper_bound)
        SELECT id
              ,'Initiated'
              ,now()
              ,slicing_mode
              ,'Manual'
              ,in_expression
              ,in_ts_lower_bound
              ,in_ts_upper_bound
         FROM core.task
        WHERE id = in_task_id;

   GET DIAGNOSTICS num_rows = ROW_COUNT;

   RETURN num_rows;
EXCEPTION
   WHEN OTHERS THEN
      RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION logs.mark_reprocess()
RETURNS NUMERIC
AS $$
DECLARE
   num_rows  numeric := 0;
BEGIN
   UPDATE p
      SET p.reprocessed         = true
     FROM logs.process p
          INNER JOIN logs.process px
                  ON px.task_id             = p.task_id
                 AND px.original_process_id = p.id
                 AND px.status              = 'Initiated';

   GET DIAGNOSTICS num_rows = ROW_COUNT;

   RETURN num_rows;
EXCEPTION
   WHEN OTHERS THEN
      RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;                           