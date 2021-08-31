#CF-Setup.sh
#!/bin/sh

PG_DATA=/usr/local/pgsql/data

mkdir -p $PG_DATA/cf_tblspc/cf_core_dat
mkdir -p $PG_DATA/cf_tblspc/cf_core_idx
mkdir -p $PG_DATA/cf_tblspc/cf_logs_dat
mkdir -p $PG_DATA/cf_tblspc/cf_logs_idx
mkdir -p $PG_DATA/cf_tblspc/cf_arch_dat
mkdir -p $PG_DATA/cf_tblspc/cf_arch_idx
mkdir -p $PG_DATA/cf_tblspc/cf_link_dat
mkdir -p $PG_DATA/cf_tblspc/cf_link_idx
mkdir -p $PG_DATA/cf_tblspc/cf_hawk_dat
mkdir -p $PG_DATA/cf_tblspc/cf_hawk_idx

chown -R Postgres:Postgres $PG_DATA/cf_tblspc

createdb -T template1 -E UTF8 -O postgres CampFire

psql -d CampFire -U Postgres < Setup.sql
psql -d CampFire -U Postgres < DropsDDL.sql
psql -d CampFire -U Postgres < ScheduleDDL.sql
psql -d CampFire -U Postgres < TaskDDL.sql

psql -d CampFire -U Postgres < LoggersDDL.sql
psql -d CampFire -U Postgres < LoggersV.sql
psql -d CampFire -U Postgres < LoggersF.sql

sed s/cf_logs/cf_arch/g  LoggersDDL.sql | sed s/logs,public/archive,public/g > LogArchDDL.sql
psql -d CampFire -U Postgres < LogArchDDL.sql
rm LogArchDDL.sql
sed s/cf_logs/cf_arch/g  LoggersV.sql | sed s/logs,public/archive,public/g > LogArchV.sql
psql -d CampFire -U Postgres < LogArchV.sql
rm LogArchV.sql

psql -d CampFire -U Postgres < ScheduleF.sql
psql -d CampFire -U Postgres < ScheduleV.sql
psql -d CampFire -U Postgres < HawkV.sql

psql -d CampFire -U Postgres < ScheduleDAT.sql
psql -d CampFire -U Postgres < TaskDAT.sql

