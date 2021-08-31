#!/bin/sh
prefix=`echo $1| sed 's/\//\\\\\//g'`
echo $prefix

pguser=$2
dbpath=`echo $3| sed 's/\//\\\\\\//g'`

pg=`cat /etc/hostconfig| grep POSTGRESQL|wc -l`
if [ $pg -eq 0 ]
then
   echo "POSTGRESQL=-YES-" >> /etc/hostconfig
fi   

cp -r PostgreSQL /Library/StartupItems 

cd /Library/StartupItems/PostgreSQL

#perl -pi -e "s/(?=.*\@PREFIX\@.*$)/$prefix/" /Library/StartupItems/PostgreSQL/PostgreSQL.template
#perl -pi -e "s/(?=.*\@PGUSER@.)/$pguser/" /Library/StartupItems/PostgreSQL/PostgreSQL.template
#perl -pi -e "s/(?=.*\@PGDATA@.)/$dbpath/" /Library/StartupItems/PostgreSQL/PostgreSQL.template
#sed 's/^prefix="\/usr\/local\/pgsql"/prefix="\'${prefix}'"/g' PostgreSQL > PostgreSQL.1
#sed 's/^PGUSER="postgres"/PGUSER="'${pguser}'"/g' PostgreSQL.1 > PostgreSQL.2
#sed 's/^PGDATA="\/Database"/PGDATA="'${dbpath}'"/g' PostgreSQL.2 > PostgreSQL.3


#sudo rm PostgreSQL.1 PostgreSQL.1

if [ -e /Library/StartupItems/PostgreSQL/PostgreSQL ]
then
  echo "Startup Item Installed Successfully . . . "
  echo "Starting PostgreSQL Server . . . "
  SystemStarter restart PostgreSQL
fi
