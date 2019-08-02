#!/bin/bash


# 설정값
CFG_NAME=""
CFG_PATH=""
CFG_INTERVAL=7
CFG_DATE_PATTERN="+_%Y%m%d"
CFG_DATE=""
CFG_AWS_BUCKET=""
CFG_AWS_PROFILE="default"

# 변수 생성
V_BASE_PATH=$( cd "$(dirname "$0")" ; pwd )
V_BACKUP_LOG=${V_BASE_PATH}"/logs/`date +%Y%m%d`.log"
V_TEMP_PATH=${V_BASE_PATH}"/temp_logs"
V_TARGET_DATE=''


# 로그 디렉토리 확인 및 생성
if [ ! -d "${V_BASE_PATH}/logs/" ] ; then
    # 디렉토리 생성
    echo "디렉토리 생성: ${V_BASE_PATH}/logs/"
    `mkdir ${V_BASE_PATH}/logs/`
fi


# 메시지 출력 및 기록(형식 지정)
function echoWformat() {
    echo "[`date +%Y-%m-%d' '%H:%M:%S` | $CFG_NAME] "$1
    echo "[`date +%Y-%m-%d' '%H:%M:%S` | $CFG_NAME] "$1 >> $V_BACKUP_LOG
}


# 도움말
V_HELP_MSG="
Log file backup to AWS S3 (ver. 0.8)

파일을 압축해서 AWS S3에 업로드하는 로그 백업 스크립트 입니다. 지정된 폴더 안에 있는 파일 중 
파일이름이 특정 날짜 패턴을 가지는 모든 파일을 압축해서 AWS S3에 업로드 합니다.
※ AWS CLI 설치 및 AWS profile 설정이 필요합니다.

usage: sh log2s3.sh [parameters]
    ex) sh log2s3.sh -n\"test_log\" -p\"/var/www/html/logs\" -i14 -b\"/log_backup\" -P\"log_profile\"

parameters:
    -h  도움말을 출력합니다.
    -n  로그 백업 이름을 설정합니다. (필수)
        S3 버킷안의 백업 폴더 이름 및 백업 파일 이름에 사용됩니다.
        ※ 주의: 같은 이름을 중복해서 사용할 경우 백업 파일이 덮어쓰기되어 소실될 수 있습니다.
    -p  백업할 로그 폴더를 설정 합니다. (필수)
        해당 폴더 안에 있는 파일에 대해 백업 작업을 수행합니다.
    -i  백업 간격을 설정 합니다.
        실행 시점에서 'i'일 전 파일에 대해 백업 작업을 수행합니다.
        '-d' 옵션이 설정되면 이 옵션은 무시됩니다.
        기본값은 '7'입니다.
    -D  날짜 형식을 설정합니다. 
        백업할 로그 파일을 비교하기 위해 로그 파일의 날짜 부분 형식을 설정합니다.
        'date' 명령의 FORMAT 형식을 사용합니다.
        '-d' 옵션이 설정되면 이 옵션은 무시됩니다.
        기본값은 '+_%Y%m%d'입니다.
    -d  백업 대상 날짜를 지정합니다.
        전달 받은 문자열 전후에 와일드카드 문자(*)를 추가 후 매칭되는 파일에 대해 백업 작업을 수행합니다.
        이 옵션이 설정될 경우 '-i', '-D' 옵션은 무시됩니다.
        ex) 20190729 -> *20190729*
            _20190729 -> *_20190729*
    -b  백업한 로그파일이 저장될 S3의 버킷 이름을 설정합니다. (필수)
    -P  S3 업로드에 사용할 AWS 프로필 이름을 지정합니다.
        기본값은 'default' 입니다.

※ Visit to GitHub: https://github.com/eminuk/log2s3
"


# 입력값 배열에 저장
args=("$@")


# 입력값 확인 및 분류
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


# TODO: 입력값 검증 로직
# 필수값 확인
if [ -z "$CFG_NAME" ] || [ -z "$CFG_PATH" ] || [ -z "$CFG_AWS_BUCKET" ] ; then
    echo "필수 입력값이 누락되어 있습니다. 도움말을 참고해 주세요. - \"sh log_backup.sh -h\""
    exit 0
fi
# CFG_PATH의 마지막 '/' 제거
CFG_PATH=${CFG_PATH%/}


# V_TARGET_DATE 값 설정
if [ -z $CFG_DATE ] ; then
    V_TARGET_DATE=`date -d "$CFG_INTERVAL day ago" "$CFG_DATE_PATTERN"`
else
    V_TARGET_DATE=$CFG_DATE
fi


# TODO: 'CFG_NAME' 이 같은 값을 가지는 프로세스 중복 실행되지 않게


# 메시지 출력
echoWformat "로그파일 백업 프로세스 시작."
echoWformat "입력값 목록: $*"
echoWformat "로그 백업 이름: $CFG_NAME"
echoWformat "백업 대상 경로: $CFG_PATH"
echoWformat "백업 대상 날짜: $V_TARGET_DATE"


# 압축된 로그파일이 저장될 임시 폴더 확인 및 생성
if [ ! -d "$V_TEMP_PATH/$CFG_NAME" ] ; then
    # 디렉토리 생성
    echoWformat "디렉토리 생성: $V_TEMP_PATH/$CFG_NAME" 
    `mkdir -p $V_TEMP_PATH/$CFG_NAME`
fi


# log 파일 압축
V_CMD_STR="tar cvzfP $V_TEMP_PATH/$CFG_NAME/${CFG_NAME}_${V_TARGET_DATE}.tar.gz *${V_TARGET_DATE}*" --remove-files
echoWformat "log 파일 압축: $V_CMD_STR"

# TODO: 표준에러 기록 형식 정비 필요
CMD_MSG=` { cd ${CFG_PATH}/ && $V_CMD_STR ; } 2>> $V_BACKUP_LOG`
if [ -z "$CMD_MSG" ] ; then
    echoWformat "로그 파일 압축 실패"

    # 압축파일 삭제
    V_CMD_STR="rm -f $V_TEMP_PATH/$CFG_NAME/${CFG_NAME}_${V_TARGET_DATE}.tar.gz"
    echoWformat "실패한 파일 삭제: ${V_CMD_STR}"
    CMD_MSG=` { $V_CMD_STR ; } 2>&1`

    echoWformat "로그파일 백업 프로세스 종료. 약 ${SECONDS} 초 소요"
    exit 1
else
    # TODO: 메시지 출력 형식 정비
    echoWformat "$CMD_MSG"
fi


# S3 버킷 확인
V_CMD_STR="aws s3api head-bucket --bucket ${CFG_AWS_BUCKET} --profile ${CFG_AWS_PROFILE}"
echoWformat "S3 버킷 확인: $V_CMD_STR"
CMD_MSG=$( { $V_CMD_STR ; } 2>&1 )


# S3 업로드 - 버킷 권한이 있을 경우
if [ -z "$CMD_MSG" ] ; then
    # S3 업로드
    V_CMD_STR="aws s3 mv ${V_TEMP_PATH}/${CFG_NAME}/ s3://${CFG_AWS_BUCKET}/${CFG_NAME}/ --recursive --profile ${CFG_AWS_PROFILE}"
    echoWformat "S3 업로드: $V_CMD_STR"
    CMD_MSG=` $V_CMD_STR 2>&1 `
    # TODO: 메시지 출력 형식 정비
    echoWformat "${CMD_MSG}"
else
    echoWformat "$CMD_MSG"
    echoWformat "S3 버킷에 접근할 수 없습니다."
fi


# 메시지 출력
echoWformat "로그파일 백업 프로세스 종료. 약 ${SECONDS} 초 소요"
exit 0