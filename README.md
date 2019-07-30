# log2s3
Log file backup to S3




https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/cli-chap-install.html


https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/cli-configure-profiles.html


https://aws.amazon.com/ko/getting-started/tutorials/backup-to-s3-cli/


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

printf [aws_access_key_id]\\n[aws_secret_access_key]\\nap-northeast-2\\njson | aws configure --profile log-backup


sh /home/schan/log2s3/log2s3.sh -n"chan_admin_backup" -p"/home/schan/log2s3/logs" -P"log-backup" -b"chance-log-backup" -i33 -D"+%Y%m"








