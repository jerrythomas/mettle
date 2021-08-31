--Setup.sql

CREATE SCHEMA Core 
AUTHORIZATION postgres; -- Core Scheduling components

CREATE TABLESPACE cf_core_dat 
         LOCATION E'C:\\Tools\\PostgreSQL\\data\\cf_tblspc\\cf_core_dat';
CREATE TABLESPACE cf_core_idx 
         LOCATION E'C:\\Tools\\PostgreSQL\\data\\cf_tblspc\\cf_core_idx';

ALTER SCHEMA Core SET TABLESPACE cf_core_dat;

CREATE TABLESPACE cf_logs_dat 
         LOCATION E'C:\\Tools\\PostgreSQL\\data\\cf_tblspc\\cf_logs_dat';
CREATE TABLESPACE cf_logs_idx 
         LOCATION E'C:\\Tools\\PostgreSQL\\data\\cf_tblspc\\cf_logs_idx';

CREATE SCHEMA Logs
 AUTHORIZATION postgres; -- Logging objects

ALTER SCHEMA Logs SET TABLESPACE cf_logs_dat;

CREATE SCHEMA archive
 AUTHORIZATION postgres;-- Logging objects

CREATE TABLESPACE cf_arch_dat 
         LOCATION E'C:\\Tools\\PostgreSQL\\data\\cf_tblspc\\cf_arch_dat';
CREATE TABLESPACE cf_arch_idx 
         LOCATION E'C:\\Tools\\PostgreSQL\\data\\cf_tblspc\\cf_arch_idx';

ALTER SCHEMA Archive SET TABLESPACE cf_arch_dat;