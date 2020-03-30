#!/bin/bash

set -e

export MONGO_HOST=${MONGO_HOST:-locahost}
export MONGO_PORT=${MONGO_PORT:-27017}

if [ ! -d /dump ];
then 
  echo 'no dump dir /dump'
  exit 1; 
else
  sub_dir=`date +%Y%m%d%H%M`
  dumpdir=/dump/${MONGO_HOST}/$sub_dir
  mkdir -p ${dumpdir}
fi


if [ -d ${dumpdir} ];then
  if [ -z $USERNAME ] && [ -z $PASSWORD ];
  then
    rs_ok=`mongo -h $MONGO_HOST --port $MONGO_PORT --eval "rs.status().ok"`
    if [ "$rs_ok" == "1" ];then
      bak_op='--oplog'
    else
      bak_op=''
    fi
    mongodump -h $MONGO_HOST --port $MONGO_PORT -o ${dumpdir} ${bak_op} --gzip >> ${dumpdir}/mongodump.log 
  else
    rs_ok=`-u $USERNAME -p $PASSWORD -h $MONGO_HOST --port $MONGO_PORT --eval "rs.status().ok"`
    if [ "$rs_ok" == "1" ];then
      bak_op='--oplog'
    else
      bak_op=''
    fi
    mongodump -u $USERNAME -p $PASSWORD -h $MONGO_HOST --port $MONGO_PORT -o ${dumpdir} --oplog --gzip >> ${dumpdir}/mongodump.log
  fi
fi

find /dump/${MONGO_HOST} -mtime +7 -type d |xargs rm -rf
