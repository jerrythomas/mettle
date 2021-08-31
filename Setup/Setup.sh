#CF-Setup.sh
#!/bin/sh
PG_USER=_postgres
PG_DATA=/Database
PG_HOME=/usr/local/postgresql/bin
TMP=/tmp

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

chown -R $PG_USER:$PG_USER $PG_DATA/cf_tblspc

sudo -u $PG_USER $PG_HOME/createdb -T template0 -E UTF8 -O $PG_USER CampFire 

$PG_HOME/psql -d CampFire -U $PG_USER < Setup.sql
cd ../SQL
$PG_HOME/psql -d CampFire -U $PG_USER < DropsDDL.sql
$PG_HOME/psql -d CampFire -U $PG_USER < ScheduleDDL.sql
$PG_HOME/psql -d CampFire -U $PG_USER < TaskDDL.sql

$PG_HOME/psql -d CampFire -U $PG_USER < LoggersDDL.sql
$PG_HOME/psql -d CampFire -U $PG_USER < LoggersV.sql
$PG_HOME/psql -d CampFire -U $PG_USER < LoggersF.sql

sed s/cf_logs/cf_arch/g  LoggersDDL.sql | sed s/logs,public/archive,public/g > $TMP/LogArchDDL.sql
$PG_HOME/psql -d CampFire -U $PG_USER < $TMP/LogArchDDL.sql
rm $TMP/LogArchDDL.sql
sed s/cf_logs/cf_arch/g  LoggersV.sql | sed s/logs,public/archive,public/g > $TMP/LogArchV.sql
$PG_HOME/psql -d CampFire -U $PG_USER < $TMP/LogArchV.sql
rm $TMP/LogArchV.sql

$PG_HOME/psql -d CampFire -U $PG_USER < ScheduleF.sql
$PG_HOME/psql -d CampFire -U $PG_USER < ScheduleV.sql
$PG_HOME/psql -d CampFire -U $PG_USER < HawkV.sql

$PG_HOME/psql -d CampFire -U $PG_USER < ScheduleDAT.sql
#$PG_USER/psql -d CampFire -U $PG_USER < TaskDAT.sql

