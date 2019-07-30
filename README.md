# log2s3
Log file backup to S3




https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/cli-chap-install.html


https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/cli-configure-profiles.html


https://aws.amazon.com/ko/getting-started/tutorials/backup-to-s3-cli/




printf [aws_access_key_id]\\n[aws_secret_access_key]\\n[ap-northeast-2]\\n[json] | aws configure --profile log_backup


sh log2s3.sh -n"test" -p"/var/local_shared/sample_logs/" -P"log_backup" -b"chance-log-backup"