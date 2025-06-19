# AWS_EC2_AUTO
## nginx-setup.sh 사전에 만듭니다.

## AWS CLI 사용
## aws configure get region
## 사용할 AMI ID 조회
![alt text](image.png)

## SSH 접속 Key 생성
![alt text](image-1.png)

## 보안그룹 ID
![alt text](image-2.png)

## 윈도우 PowerShell 사용 시 백틱 ` 으로 문장 연결 합니다.

## 시나리오
[1] EC2 하나 생성 후 nginx 설치 + index.html 배포
[2] 해당 EC2로 AMI 생성
[3] Launch Template + ASG + ALB 구성
[4] index.html 수정 시 → AMI 새로 생성
[5] Launch Template 새 버전 → ASG 점진적 롤링 업데이트

## EC2 1대 생성 + nginx 설치
# 1. EC2 생성
aws ec2 run-instances `
  --image-id ami-0c9c942bd7bf113a2 `
  --instance-type t3.micro `
  --key-name EC2-Auto-Key `
  --security-group-ids sg-07a03565 `
  --user-data file://nginx-setup.sh

## Error
An error occurred (UnauthorizedOperation) when calling the RunInstances operation: You are not authorized to perform this operation. User: arn:aws:iam::086015456585:user/DevUser0002 is not authorized to perform: ec2:RunInstances on resource: arn:aws:ec2:ap-northeast-2:086015456585:instance/* because no identity-based policy allows the ec2:RunInstances action. 

## 위의 에러 발생 시
![alt text](image-3.png)

## 권한 추가 중 10개 초과 문제가 다음일 경우도 있음
![alt text](image-4.png)

## AmazonEC2FullAccess 권한을 사용자 그룹에 주고, 사용자 그룹에 사용자를 속하도록 함
## 사용자 그룹 예시
![alt text](image-5.png)

## 사용자를 그룹에 포함시킴
![alt text](image-6.png)
![alt text](image-7.png)

## VM 생성 확인
{
    "ReservationId": "r-0f7e31d193251855a",
    "OwnerId": "086015456585",
    "Groups": [],
    "Instances": [
        {
            "Architecture": "x86_64",
            "BlockDeviceMappings": [],
            "ClientToken": "a4da16d0-2364-42f0-815a-9cabafa7f59a",
            "EbsOptimized": false,
            "EnaSupport": true,
            "Hypervisor": "xen",
            "NetworkInterfaces": [
                {
                    "Attachment": {
                        "AttachTime": "2025-06-19T07:17:48+00:00",
                        "AttachmentId": "eni-attach-00ad285364864a4e3",
                        "DeleteOnTermination": true,
                        "DeviceIndex": 0,
                        "Status": "attaching",
                        "NetworkCardIndex": 0
                    },
                    "Description": "",
                    "Groups": [
                        {
                            "GroupId": "sg-07a03565",
                            "GroupName": "default"
                        }
                    ],
                    "Ipv6Addresses": [],
                    "MacAddress": "0a:24:97:37:60:41",
                    "NetworkInterfaceId": "eni-0c969969db6f930f5",
                    "OwnerId": "086015456585",
                    "PrivateDnsName": "ip-172-31-47-28.ap-northeast-2.compute.internal",
                    "PrivateIpAddress": "172.31.47.28",

                    ... 이하 생략 ...
## VM 생성 확인
![alt text](image-8.png)

