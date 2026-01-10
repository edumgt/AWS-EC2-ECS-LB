# AWS EC2 Auto - 0702 Spring Boot 준비

## 개요
- 기존 AMI에 Spring Boot를 올리기 위한 JDK/FTP 설정 절차를 정리했습니다.
- 명령어 중심으로 기록되어 있어 단계별로 실행하면 됩니다.

## AMI 에 Spring Boot 올리기 위한 작업
## 기존 AMI 중 Nginx 미설치 AMI 인스탄스 생성
## sudo apt update
## sudo apt install openjdk-17-jdk
## root@ip-172-31-35-116:~# java --version
## openjdk 17.0.15 2025-04-15
## OpenJDK Runtime Environment (build 17.0.15+6-Ubuntu-0ubuntu122.04)
## OpenJDK 64-Bit Server VM (build 17.0.15+6-Ubuntu-0ubuntu122.04, mixed mode, sharing)

## ftpd 데몬 설치
## sudo apt install vsftpd -y
## sudo systemctl start vsftpd
## sudo systemctl enable vsftpd
## vi /etc/vsftpd.conf

## vi 에서 파일쓰기 권한 주기
anonymous_enable=NO
local_enable=YES
write_enable=YES

## sudo systemctl restart vsftpd

## sudo useradd -m ftpuser
## sudo passwd ftpuser
ftpuser0001

## java -jar ./app.jar
