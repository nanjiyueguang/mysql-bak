#!/bin/bash

DB_USER=${DB_USER:-${MYSQL_ENV_DB_USER}}
DB_PASS=${DB_PASS:-${MYSQL_ENV_DB_PASS}}
DB_NAME=${DB_NAME:-${MYSQL_ENV_DB_NAME}}
DB_HOST=${DB_HOST:-${MYSQL_ENV_DB_HOST}}
ALL_DATABASES=${ALL_DATABASES}
IGNORE_DATABASE=${IGNORE_DATABASE}


if [[ ${DB_USER} == "" ]]; then
	echo "Missing DB_USER env variable"
	exit 1
fi
if [[ ${DB_PASS} == "" ]]; then
	echo "Missing DB_PASS env variable"
	exit 1
fi
if [[ ${DB_HOST} == "" ]]; then
	echo "Missing DB_HOST env variable"
	exit 1
fi

if [[ ${DB_PORT} == "" ]]; then
	echo "Missing DB_PORT env variable"
	exit 1
fi

if [ ! -d "/mysqldump/${DB_HOST}/$(date +'%Y%m%d%H')" ];then
	mkdir -p /mysqldump/${DB_HOST}/$(date +'%Y%m%d%H')
fi 

DSN="--user=${DB_USER} --password=${DB_PASS} --host=${DB_HOST} --port=${DB_PORT}"
log_bin_on=$(mysql ${DSN} -Ne 'show variables like "log_bin"'|awk '{print $2}')

if [[ ${ALL_DATABASES} == "" ]]; then
	echo "Missing DB_NAME env variable"
	exit 1
elif [ "${log_bin_on}" == 'ON' ];then
	mysql $DSN -Ne "show databases;"| grep -Ev "information_schema|performance_schema|sys" | xargs mysqldump $DSN --databases --compress --flush-logs --flush-privileges --master-data=2 --routines --single-transaction --dump-date --log-error=/mysqldump/${DB_HOST}/$(date +'%Y%m%d%H')/mysqldump.log.err |gzip > /mysqldump/${DB_HOST}/$(date +'%Y%m%d%H')/${DB_HOST}.consistent.dump.gz 
elif [ "${log_bin_on}" == 'OFF' ];then
    mysql $DSN -Ne "show databases;"| grep -Ev "information_schema|performance_schema|sys" | xargs mysqldump ${DSN} --databases --compress --skip-lock-tables --routines --dump-date --log-error=/mysqldump/${DB_HOST}/$(date +'%Y%m%d%H')/mysqldump.log.err |gzip > /mysqldump/${DB_HOST}/$(date +'%Y%m%d%H')/${DB_HOST}.dump.gz    
else
    echo "log_bin error"
    exit 1
fi


## delete obsolete back file
find /mysqldump/${DB_HOST} -mtime +5 -type d |xargs rm -rf
