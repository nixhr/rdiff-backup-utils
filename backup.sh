#!/bin/bash
#
# Sun Jan 22 13:52:01 CET 2017
#
# exit codes:
#
# 0 - rdiff-backup successful
# 1 - invalid arguments
# 2 - another rdiff-backup process found running (by checking TMPFILE)
# 3 - backup failed for some reason
# 4 - missing configuration
# 5 - mountpoint not mounted

INIFILE="/opt/backup/backup.ini"
[[ -z $1 ]] && printf "FATAL: Missing argument\n\nUsage:\n$0 <backup_profile>\n" && exit 1

PROFILE=$1
[[ -z $(crudini --get $INIFILE |grep "^$PROFILE$") ]] && printf "FATAL: missing config section [${PROFILE}] in $INIFILE\n" && exit 4

HOST_ADDRESS=$(crudini --get $INIFILE $PROFILE host_address)
[[ -z $HOST_ADDRESS ]] && printf "FATAL: missing 'host_address' config option for profile ${PROFILE} in $INIFILE\n" && exit 4

SSH_PORT=$(crudini --get $INIFILE $PROFILE ssh_port)
[[ -z $SSH_PORT ]] && printf "FATAL: missing 'ssh_port' config option for profile ${PROFILE} in $INIFILE\n" && exit 4

SSH_IDENTITY=$(crudini --get $INIFILE $PROFILE ssh_identity)
[[ -z $SSH_IDENTITY ]] && printf "FATAL: missing 'ssh_identity' config option for profile ${PROFILE} in $INIFILE\n" && exit 4

BASE_DIR=$(crudini --get $INIFILE $PROFILE base_dir)
[[ -z $BASE_DIR ]] && printf "FATAL: missing 'base_dir' config option for profile ${PROFILE} in $INIFILE\n" && exit 4

BACKUP_DIR=$(crudini --get $INIFILE $PROFILE backup_dir)
[[ -z $BACKUP_DIR ]] && printf "FATAL: missing 'backup_dir' config option for profile ${PROFILE} in $INIFILE\n" && exit 4

EXCLUDE=$(crudini --get $INIFILE $PROFILE exclude)
[[ -z $EXCLUDE ]] && printf "FATAL: missing 'exclude' config option for profile ${PROFILE} in $INIFILE\n" && exit 4

RETENTION_PERIOD=$(crudini --get $INIFILE $PROFILE retention_period)
[[ -z $RETENTION_PERIOD ]] && printf "FATAL: missing 'retention_period' config option for profile ${PROFILE} in $INIFILE\n" && exit 4

MOUNT_CHECK=$(crudini --get $INIFILE $PROFILE mount_check)
[[ -z $MOUNT_CHECK ]] && printf "FATAL: missing 'mount_check' config option for profile ${PROFILE} in $INIFILE\n" && exit 4

if ! mountpoint -q ${MOUNT_CHECK} 
then
  printf "FATAL: $MOUNT_CHECK not mounted\n" 
  exit 5
fi

set -f 

for i in ${EXCLUDE}
do
  EXCLUDE_CMD="$EXCLUDE_CMD --exclude $i"
done

TMPFILE="/tmp/rdiff-backup.${PROFILE}.in_progress"
[[ -f $TMPFILE ]] && printf "\nFATAL: rdiff-backup another process for profile ${PROFILE} already running\n" && exit 2
touch $TMPFILE

[[ ! -d ${BACKUP_DIR} ]] && printf "Destination directory ${BACKUP_DIR} does not exist. Initializing...\n" && mkdir -p ${BACKUP_DIR}

if rdiff-backup --terminal-verbosity 0 --preserve-numerical-ids --remote-schema "ssh -o StrictHostKeyChecking=no -p ${SSH_PORT} -i ${SSH_IDENTITY} %s rdiff-backup" ${EXCLUDE_CMD} ${HOST_ADDRESS}::${BASE_DIR} $BACKUP_DIR
then
  rdiff-backup --terminal-verbosity 0 --force --remove-older-than ${RETENTION_PERIOD} ${BACKUP_DIR}
  touch ${BACKUP_DIR}.LAST-OK
  rm $TMPFILE
  exit 0
else
  rdiff-backup --check-destination-dir ${BACKUP_DIR}
  rm $TMPFILE
  exit 3
fi
