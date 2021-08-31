--Setup.sql

-- Core Scheduling components
CREATE TABLESPACE cf_core_dat
         LOCATION '/Database/cf_tblspc/cf_core_dat';
CREATE TABLESPACE cf_core_idx
         LOCATION '/Database/cf_tblspc/cf_core_idx';

-- Logging objects
CREATE TABLESPACE cf_logs_dat
         LOCATION '/Database/cf_tblspc/cf_logs_dat';
CREATE TABLESPACE cf_logs_idx
         LOCATION '/Database/cf_tblspc/cf_logs_idx';

-- For the archived logs
CREATE TABLESPACE cf_arch_dat
         LOCATION '/Database/cf_tblspc/cf_arch_dat';
CREATE TABLESPACE cf_arch_idx
         LOCATION '/Database/cf_tblspc/cf_arch_idx';

-- For the relation diagrams
CREATE TABLESPACE cf_link_dat
         LOCATION '/Database/cf_tblspc/cf_link_dat';
CREATE TABLESPACE cf_link_idx
         LOCATION '/Database/cf_tblspc/cf_link_idx';

-- For the analytical reports
CREATE TABLESPACE cf_hawk_dat
         LOCATION '/Database/cf_tblspc/cf_hawk_dat';
CREATE TABLESPACE cf_hawk_idx
         LOCATION '/Database/cf_tblspc/cf_hawk_idx';



CREATE SCHEMA core;   --AUTHORIZATION "postgres" -- Core Scheduling components
CREATE SCHEMA logs;   --AUTHORIZATION "postgres" -- Logging objects
CREATE SCHEMA archive;--AUTHORIZATION "postgres" -- For the archived logs
CREATE SCHEMA links;  --AUTHORIZATION "postgres" -- For the relation diagrams
CREATE SCHEMA hawk;   --AUTHORIZATION "postgres" -- For the analytical reports
