#!/bin/bash

# config variables
CFG_NAME=""
CFG_PATH=""
CFG_INTERVAL=7
CFG_DATE_PATTERN="+%Y%m%d"
CFG_DATE=""
CFG_AWS_BUCKET="log-backup"
CFG_AWS_PROFILE="default"

# variables
V_BASE_PATH=$( cd "$(dirname "$0")" ; pwd )
V_BACKUP_LOG=${V_BASE_PATH}"/logs/`date +%Y%m%d`.log"
V_TEMP_PATH=${V_BASE_PATH}"/temp_logs"
V_TARGET_DATE=''

# arguments to array
args=("$@")


# check and create directory for this process log
if [ ! -d "${V_BASE_PATH}/logs/" ] ; then
    # create directory
    `mkdir ${V_BASE_PATH}/logs/`
fi


# echo message with format
function echoWformat() {
    echo "[`date +%Y-%m-%d' '%H:%M:%S` | $CFG_NAME] "$1
    echo "[`date +%Y-%m-%d' '%H:%M:%S` | $CFG_NAME] "$1 >> $V_BACKUP_LOG
}


# help message
V_HELP_MSG="Log backup to AWS S3 script (ver. 1.0)

there desc string...

usage: sh log_backup.sh [parameters]
    ex) sh log_backup.sh -n\"test_log\" -p\"/var/www/html/logs\"

parameters:
    -h Show help message (this) - required
    -n Set name. It used to directory names(temp and S3) and filename. - required
    -p Path with log file. This process backs up the files in this directory.
    -i Interval of backup dates. This prdcess backs up the 'Interval' ago days. If '-d' arg set, this arg is ignored.
    -D Date pattern. ex) +%Y%m%d
    -d Target date. Backs up files of the specified date. ex) 20190729 or 2019-07-29 or etc...
    -b S3 Bucket name. Default value is 'log-backup'
    -P aws profile name. Default value is 'default'
"

# check arguments and assort
for ((i=0; i<$#; i++))
do
    case ${args[$i]:0:2} in
        
        -n) CFG_NAME=${args[$i]:2:$((${#args[$i]}-2))} ;;
        -p) CFG_PATH=${args[$i]:2:$((${#args[$i]}-2))} ;;
        -i) CFG_INTERVAL=${args[$i]:2:$((${#args[$i]}-2))} ;;
        -D) CFG_DATE_PATTERN=${args[$i]:2:$((${#args[$i]}-2))} ;;
        -d) CFG_DATE=${args[$i]:2:$((${#args[$i]}-2))} ;;
        -b) CFG_AWS_BUCKET=${args[$i]:2:$((${#args[$i]}-2))} ;;
        -P) CFG_AWS_PROFILE=${args[$i]:2:$((${#args[$i]}-2))} ;;
        -h) echo "$V_HELP_MSG"
            exit 0 ;;
        *) echo "$V_HELP_MSG"
            exit 0 ;;
    esac
done

# TODO: input validation
# required arguments
if [ -z "$CFG_NAME" ] || [ -z "$CFG_PATH" ] ; then
    echo "required arguments is missing. Check help message - \"sh log_backup.sh -h\""
    exit 0
fi
# CFG_PATH remove last '/'
CFG_PATH=${CFG_PATH%/}


# set V_TARGET_DATE
if [ -z $CFG_DATE ] ; then
    V_TARGET_DATE=`date -d "$CFG_INTERVAL day ago" "$CFG_DATE_PATTERN"`
else
    V_TARGET_DATE=$CFG_DATE
fi


# TODO: same 'CFG_NAME' process check


# echo message 
echoWformat "log-backup process start."
echoWformat "Arguments list: $*"
echoWformat "Name of log backup: $CFG_NAME"
echoWformat "Target log path: $CFG_PATH"
echoWformat "Target date: $V_TARGET_DATE"


# check and create directory for temporary file
if [ ! -d "$V_TEMP_PATH/$CFG_NAME" ] ; then
    # create directory
    echoWformat "Create directory: $V_TEMP_PATH/$CFG_NAME" 
    `mkdir -p $V_TEMP_PATH/$CFG_NAME`
fi


# zip log files
V_CMD_STR="tar cvzfP $V_TEMP_PATH/$CFG_NAME/${CFG_NAME}__${V_TARGET_DATE}.tar.gz *_${V_TARGET_DATE}*" #--remove-files
echoWformat "Zip log files: $V_CMD_STR"
CMD_MSG=` { cd ${CFG_PATH}/ && $V_CMD_STR ; } 2>&1 `
echoWformat "$CMD_MSG"


# S3 bucketet check
V_CMD_STR="aws s3api head-bucket --bucket ${CFG_AWS_BUCKET} --profile ${CFG_AWS_PROFILE}"
echoWformat "Bucket check: $V_CMD_STR"
CMD_MSG=$( { $V_CMD_STR ; } 2>&1 )
echoWformat "$CMD_MSG"


# S3 upload - if bucket is ok
if [ -z "$CMD_MSG" ] ; then
    # S3 upload
    V_CMD_STR="aws s3 mv ${V_TEMP_PATH}/${CFG_NAME}/ s3://${CFG_AWS_BUCKET}/${CFG_NAME}/ --recursive --profile ${CFG_AWS_PROFILE}"
    echoWformat "S3 Upload: $V_CMD_STR"
    CMD_MSG=` { $V_CMD_STR ; } 2>&1 `
    echoWformat "$CMD_MSG"
else
    echoWformat "Bucket not found."
fi


echo -e "\n\n\n\n"


# echo message
echoWformat "log-backup process finished at $SECONDS sec"