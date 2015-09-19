#!/bin/bash

[ $# -ne 3 ] && echo "$0 dbname user password" && exit 1

DATE=$(date +%Y-%m-%d)

## 
SCRIPT_DIR=$(cd $(dirname $0); pwd)
KNIFE_HOME=${SCRIPT_DIR}/..
MNESIA_BASE=${KNIFE_HOME}/mnesia

HOSTNAME=`env hostname`
NODENAME=controller-knife@${HOSTNAME%%.*}

MNESIA_DIR=${MNESIA_BASE}/${NODENAME}

BACKUP_DIR=${KNIFE_HOME}/backup_${DATE}
[ -d ${BACKUP_DIR} ] || mkdir -p ${BACKUP_DIR}

## mnesia 
cp -r ${MNESIA_DIR} ${BACKUP_DIR}/mnesia

## image
IMAGE_DIR=${KNIFE_HOME}/plugins/diablo_controller-1.0.0/hdoc/image
cp -r ${IMAGE_DIR} ${BACKUP_DIR}/image

## db
db=$1
user=$2
passwd=$3

mysqldump=$(which mysqldump)

# ${mysqldump} -hlocalhost -u${user} -p${passwd} \
#     --default-character-set=utf8 \
#     --opt \
#     --extended-insert=false \
#     --hex-blob \
#     --single-transaction ${db} > ${BACKUP_DIR}/${db}-${DATE}.sql


${mysqldump} -hlocalhost -u${user} -p${passwd} \
    --default-character-set=utf8 ${db} > ${BACKUP_DIR}/${db}-${DATE}.sql


## zip
TAR=diablo_backup-${DATE}.tar.gz
tar -zcf ${TAR} ${BACKUP_DIR}

cp ${TAR} /home/diablo

if [ $? -eq 0 ]; then
    echo "success to backup !!"
    rm -f ${TAR}
    rm -rf ${BACKUP_DIR}
    exit 0
else
    echo "failed to backup !!"
    exit 1
fi

