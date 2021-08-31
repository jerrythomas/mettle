--Setup.sql
mk
-- Core Scheduling components
CREATE TABLESPACE cf_core_dat
         LOCATION '/usr/local/pgsql/data/cf_tblspc/cf_core_dat';
CREATE TABLESPACE cf_core_idx
         LOCATION '/usr/local/pgsql/data/cf_tblspc/cf_core_idx';

-- Logging objects
CREATE TABLESPACE cf_logs_dat
         LOCATION '/usr/local/pgsql/data/cf_tblspc/cf_logs_dat';
CREATE TABLESPACE cf_logs_idx
         LOCATION '/usr/local/pgsql/data/cf_tblspc/cf_logs_idx';

-- For the archived logs
CREATE TABLESPACE cf_arch_dat
         LOCATION '/usr/local/pgsql/data/cf_tblspc/cf_arch_dat';
CREATE TABLESPACE cf_arch_idx
         LOCATION '/usr/local/pgsql/data/cf_tblspc/cf_arch_idx';

-- For the relation diagrams
CREATE TABLESPACE cf_link_dat
         LOCATION '/usr/local/pgsql/data/cf_tblspc/cf_arch_dat';
CREATE TABLESPACE cf_link_idx
         LOCATION '/usr/local/pgsql/data/cf_tblspc/cf_arch_idx';

-- For the analytical reports
CREATE TABLESPACE cf_hawk_dat
         LOCATION '/usr/local/pgsql/data/cf_tblspc/cf_task_dat';
CREATE TABLESPACE cf_hawk_idx
         LOCATION '/usr/local/pgsql/data/cf_tblspc/cf_task_idx';



CREATE SCHEMA core;   --AUTHORIZATION "Postgres" -- Core Scheduling components
CREATE SCHEMA logs;   --AUTHORIZATION "Postgres" -- Logging objects
CREATE SCHEMA archive;--AUTHORIZATION "Postgres" -- For the archived logs
CREATE SCHEMA links;  --AUTHORIZATION "Postgres" -- For the relation diagrams
CREATE SCHEMA hawk;   --AUTHORIZATION "Postgres" -- For the analytical reports
