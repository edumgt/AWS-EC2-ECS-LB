# AWS EC2 Auto - 운영 점검 및 스트레스 테스트

## 개요
- SSH 접속/보안그룹 점검과 Nginx 재설치 과정을 캡처와 함께 정리했습니다.
- 스트레스 테스트용 Launch Template 생성 예시를 포함했습니다.

## ssh -i "EC2-Auto-Key.pem" root@13.125.106.36
## 서버 접속이 안되어 SG 확인
![alt text](image-27.png)

## lsof -i :80
## apt install net-tools
## netstat -tulnp | grep ':80'
## apt update
## apt install nginx -y
## systemctl start nginx
## 80 리스너 없어서 nginx 재설치


## 재설치 후 ALB 주소로 접속 후 확인
![alt text](image-28.png)

## healthy 확인
![alt text](image-29.png)



## 
aws ec2 create-launch-template `
  --launch-template-name stress-test-template `
  --version-description "v1" `
  --launch-template-data '{
    "ImageId": "ami-0594aa3b1a9017b0a",  
    "InstanceType": "t2.micro",
    "KeyName": "MyNginXKey",
    "SecurityGroupIds": ["sg-07a03565"],
    "UserData": "'"$(base64 -w 0 <<EOF
#!/bin/bash
stress --cpu 2 --timeout 600
EOF
)"'"
  }'
