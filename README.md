# _Log to S3_

## _Log to S3_ 란
- 로그 파일을 _AWS S3서비스_ 로 백업하는 _linux bash shell script_ 입니다.
- 사용자가 지정한 폴더의 로그 파일 이름의 날짜 부분을 매칭해서 백업(이관) 작업을 진행 합니다.
- 백업 시 폴더안에 매칭된 모든 파일을 압축 후 _S3_ 에 업로드 합니다.
- _S3_ 에 파일을 업로드 하기 위해 [_AWS CLI_](https://aws.amazon.com/ko/cli/) 를 사용합니다.

---
## 설치
_Log to S3_ 는 Git clone 을 이용해서 간편하게 설치 하실 수 있습니다.
``` bash
git clone https://github.com/eminuk/log2s3.git
```

---
## _Log to S3_ 사용법

### 기본 사용법
_Log to S3_ 를 최소한의 옵션만으로 실행 할 경우 예제 입니다.  
(옵션에 대한 상세 정보는 [_옵션 설명_](#옵션-설명)을 참고해 주세요.)
``` bash
sh log2s3.sh -n"log_name" -p"/home/log2s3/logs" -b"log-backup"
```
위와 같이 실행 시 `/home/log2s3/logs` 폴더에 있는 파일 중 7일전 날짜 형식과 일치하는 파일을 압축해서 _S3_ 에 백업 합니다.  
(백업한 파일은 서버에서 삭제됩니다.)  
예를 들어 7일 전 날짜가 `2019년 07월 30일` 일 경우 아래와 파일 들이 백업 됩니다. 기본 날짜 형식은 +_%Y%m%d 입니다.  
- 기본 형식 앞부분에 `_`문자가 포함되어 있는 것에 주의해 주세요.  
- 참고: [_옵션 설명_](#옵션-설명)
```
sample_20190730.log  info_20190730_log  sample_20190730  sample_20190730.txt
```
아래 파일들은 백업되지 않습니다.
```
20190730.log  20190731.log  2019-07-30.log  sample_0730.log  sample_190730_log
```


### 심화 사용법

#### 백업 간격 지정
`-i` 옵션을 이용해서 백업 간격을 지정할 수 있습니다. 스크립트 실행 시 백업할 날짜를 계산하는데 사용됩니다. 실행 시점 기준 `i`일 전 날짜와 매칭되는 파일을 백업합니다.  
- 기본적으로 계산된 날짜 하루에 해당하는 파일을 백업합니다.  
- 만약 여러 날짜에 해당하는 파일을 백업 하시려면 스크립트를 여러번 실행 하셔야 합니다.
- `-i` 옵션과 `-D` 옵션을 응용하면 월단위 백업이 가능합니다.  
(참고: [_응용: 월단위 백업_](#응용:-월단위-백업))

#### 날짜 형식 지정
`-D` 옵션을 이용해서 날짜 형식을 지정할 수 있습니다. 리눅스 기본 명령어인 _date_ 명령의 _FORMAT_ 형식을 사용합니다.  
※ _date_ 명령의 _FORMAT_ 형식에 대한 상세 정보는 아래 사이트를 참조하시면 됩니다
- https://zetawiki.com/wiki/%EB%A6%AC%EB%88%85%EC%8A%A4_date

예를 들어 다음과 같이 실핼 시 
``` bash
sh log2s3.sh -n"log_name" -p"/home/log2s3/logs" -b"log-backup" -D"+%Y-%m-%d"
```
아래와 파일 들이 백업 됩니다.
```
2019-07-30.log
```
아래 파일들은 백업되지 않습니다.
```
sample_20190730.log  info_20190730_log  sample_20190730  sample_20190730.txt  20190730.log  20190731.log  sample_0730.log  sample_190730_log
```

#### 특정 날짜 백업
`-d` 옵션을 이용해서 특정 날짜를 지정해서 백업을 진행 할 수 있습니다.
예를 들어 아래와 같이 실행하면, 이름에 `20190730`를 포함하는 파일을 백업 합니다.
``` bash
sh log2s3.sh -n"log_name" -p"/home/log2s3/logs" -b"log-backup" -d"20190730"
```
이 경우 아래와 같은 파일 들이 백업 됩니다.
```
20190730.log  sample20190730.log  20190730_log
```

`-d` 옵션으로 지정된 값을 포함하는 모든 파일이 백업 되므로 이를 응용해서 다음과 같이 사용이 가능합니다.

예) `sample` 파일 백업
``` bash
sh log2s3.sh -n"log_name" -p"/home/log2s3/logs" -b"log-backup" -d"sample"
```
이 경우 아래와 같은 파일 들이 백업 됩니다.
```
sample_20190730.txt  sample20190730.log  logsample
```
예) `.log` 파일 백업
``` bash
sh log2s3.sh -n"log_name" -p"/home/log2s3/logs" -b"log-backup" -d".log"
```
이 경우 아래와 같은 파일 들이 백업 됩니다.
```
sample_20190731.log  sample20190630.log  logsa.log.tar
```

#### _AWS CLI_ 프로필 지정
`-P` 옵션을 이용해서 백업에 사용할 _AWS CLI_ 프로필을 지정할 수 있습니다.
``` bash
sh log2s3.sh -n"log_name" -p"/home/log2s3/logs" -b"log-backup" -P"profile_name"
```

#### 응용: 월단위 백업
`-i` 옵션과 `-D` 옵션을 응용하면 월단위 백업이 가능합니다.
`-D` 옵션으로 년/월 단위까지 형식을 지정해 주고 `-i` 옵션으로 32일 간격을 지정하면 2달전 파일들이 백업됩니다.
``` bash
sh log2s3.sh -n"log_name" -p"/home/log2s3/logs" -b"log-backup" -D"+%Y%m" -i32
```
이 경우 아래와 같은 파일 들이 백업 됩니다.
```
sample_20190730.txt  sample20190715.log  20190701.log  sample_201907_log
```


### _crontab_ 등록
로그 백업은 보통 주기적, 반복적으로 이루어 져야 합니다. 때문에 _crontab_ 에 등록해 두면 편리 합니다.  
아래 내용은 _crontab_ 등록 예시 입니다.
``` bash
# 월단위 백업
01 00 01 * * sh /home/log2s3/log2s3.sh -n"log_name" -p"/home/log2s3/logs" -b"log-backup" -i33 -D"+%Y%m"
```
보다 자새한 내용은 아래 사이트를 참조하시면 됩니다.
- https://zetawiki.com/wiki/%EB%A6%AC%EB%88%85%EC%8A%A4_%EB%B0%98%EB%B3%B5_%EC%98%88%EC%95%BD%EC%9E%91%EC%97%85_cron,_crond,_crontab


### _Log to S3_ 의 로그 파일
_Log to S3_ 의 로그 파일은 설치 폴더내 `logs/` 폴더안에 날짜별로 생성됩니다.
예)
``` 
# ls logs/
20190730.log
```


---
## 옵션 설명
플레그 | 설명 | 기본 값 | 필수 여부
:-: | :- | :-: | :-:
-h | 도움말을 출력합니다.
-n | 로그 백업 이름을 설정합니다. S3 버킷안의 백업 폴더 이름 및 백업 파일 이름에 사용됩니다.  ※ 주의: 같은 이름을 중복해서 사용할 경우 백업 파일이 덮어쓰기되어 소실될 수 있습니다. | | 필수
-p | 백업할 로그 폴더를 설정 합니다. 해당 폴더 안에 있는 파일에 대해 백업 작업을 수행합니다. | | 필수
-i | 백업 간격을 설정 합니다. 실행 시점에서 'i'일 전 파일에 대해 백업 작업을 수행합니다. '-d' 옵션이 설정되면 이 옵션은 무시됩니다. |7 | 
-D | 날짜 형식을 설정합니다. 백업할 로그 파일을 비교하기 위해 로그 파일의 날짜 부분 형식을 설정합니다. 'date' 명령의 FORMAT 형식을 사용합니다. '-d' 옵션이 설정되면 이 옵션은 무시됩니다. | +_%Y%m%d | 
-d | 백업 대상 날짜를 지정합니다. 전달 받은 문자열 전후에 와일드카드 문자(*)를 추가 후 매칭되는 파일에 대해 백업 작업을 수행합니다. 이 옵션이 설정될 경우 '-i', '-D' 옵션은 무시됩니다. <br />ex) 20190729 -> *20190729* <br />_20190729 -> *_20190729* | | 
-b | 백업한 로그파일이 저장될 S3의 버킷 이름을 설정합니다 | | 필수
-P | S3 업로드에 사용할 AWS 프로필 이름을 지정합니다. | default | 

---
## 참고

### _AWS CLI_ 설치 여부 확인
_AWS CLI_ 설치 여부 확인은 다음 명령어 실행 시 버전 정보가 표기되면 _AWS CLI_ 가 설치되어 있는 것 입니다.
``` bash
aws --v
```

설치 되어 있을 경우 결과 예시:
``` 
aws-cli/1.16.102 Python/2.7.16 Linux/4.14.128-112.105.amzn2.x86_64 botocore/1.12.92
```

설치 되어 있지 알을 경우 결과 예시: 
``` 
-bash: aws: command not found
```


### _AWS CLI_ 설치
_AWS CLI_ 설치가 필요할 경우 아래 사이트를 참조하시면 됩니다.
- https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/cli-chap-install.html


### 서버에 _AWS CLI_ 프로필 등록
_AWS CLI_ 프로필에 저장된 인증 정보로 _AWS_ 서비스를 이용합니다. 프로필을 설정 하려면 아래 명령을 이용 하시면 됩니다.  
(설정 과정에 필요한 _AWS Access Key ID_, _AWS Secret Access Key_ 정보에 대한 내용은 [_AWS IAM 사용자_ 및 _Credentials_ 생성](#_AWS-IAM-사용자_-및-_Credentials_-생성) 참조.)
``` bash
aws configure --profile profile_name
```

위 명령 중 _profile_name_ 은 원하시는 프로필 이름으로 대체해서 넣으시면 됩니다. 이후 아래와 같이 4가지 입력값을 순차적으로 입력해 주시면 프로필 설정이 완료 됩니다.
```
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: ap-northeast-2
Default output format [None]: json
```

입력값:
- AWS Access Key ID: 명령 요청을 인증하기 위한 자격 증명의 일부로 사용되는 AWS 액세스 키
- AWS Secret Access Key: 명령 요청을 인증하기 위한 자격 증명의 일부로 사용되는 AWS 비밀 키
- Default region name: AWS 리전
- Default output format: 출력 포멧, 보통 _json_ 을 입력하시면 됩니다.

보다 자새한 내용은 아래 사이트를 참조하시면 됩니다.
- https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/cli-configure-profiles.html
- https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/cli-configure-files.html


## _AWS IAM 사용자_ 및 _Credentials_ 생성
_AWS IAM 사용자_ 및 _Credentials_ 생성에 대한 자새한 내용은 아래 사이트를 참조하시면 됩니다.
- https://aws.amazon.com/ko/getting-started/tutorials/backup-to-s3-cli/

---
## 라이선스 정보
- Apache License 2.0

---
## Visit to GitHub
- https://github.com/eminuk/log2s3
