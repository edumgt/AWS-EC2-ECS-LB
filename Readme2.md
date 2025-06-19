## AMI 생성
## 생성 대상 Instance ID - AMI ID 가 아닙니다. 
![alt text](image-9.png)

aws ec2 create-image `
  --instance-id i-0af9db12c50a70c8f `
  --name "nginx-ami-2025-06-19" `
  --no-reboot

## {
##    "ImageId": "ami-0d3fb6fb6c746f131"
## }
![alt text](image-10.png)

## 런치 템플릿 작성
## json "" 문제로 오류가 있어서 json 을 별도로 만듬

aws ec2 create-launch-template `
  --launch-template-name nginx-lt `
  --launch-template-data file://launch-template.json

## 이상 없으면
{
    "LaunchTemplate": {
    "LaunchTemplate": {
        "LaunchTemplateId": "lt-0067eae213ccbf061",
        "LaunchTemplateName": "nginx-lt",
        "CreateTime": "2025-06-19T07:34:47+00:00",
        "CreatedBy": "arn:aws:iam::086015456585:user/DevUser0002",
        "DefaultVersionNumber": 1,
        "LatestVersionNumber": 1,
        "Operator": {
            "Managed": false
        }
    }
}

## 콘솔에서 템플릿 확인
![alt text](image-11.png)

## ALB 시나리오
ALB (80포트)
  ↓
Target Group (헬스 체크 포함)
  ↓
Auto Scaling Group (최소 1 / 최대 5)
  ↓
Launch Template (AMI 기반 nginx 인스턴스)

## 여러개의 VM 이 생성됨으로 가상의 네트웍 구성 즉, VPC 작업
## aws ec2 create-vpc --cidr-block 10.0.0.0/16
{
    "Vpc": {
        "OwnerId": "086015456585",
        "InstanceTenancy": "default",
        "Ipv6CidrBlockAssociationSet": [],
        "CidrBlockAssociationSet": [
            {
                "AssociationId": "vpc-cidr-assoc-07971cc8e75107047",
                "CidrBlock": "10.0.0.0/16",
                "CidrBlockState": {
                    "State": "associated"
                }
            }
        ],
        "IsDefault": false,
        "VpcId": "vpc-0ecdd43bad4b17796",
        "State": "pending",
        "CidrBlock": "10.0.0.0/16",
        "DhcpOptionsId": "dopt-ca9518a1"
    }
}

## 콘솔에서 확인
![alt text](image-12.png)

## 서브넷 구성
☑️ 서브넷이란?
VPC 내부의 IP 주소 범위를 쪼개놓은 네트워크 구획입니다.
EC2, ALB, RDS 등 모든 AWS 리소스는 서브넷에 속해 있어야만 생성 가능합니다.

📌 예시:
VPC: 10.0.0.0/16
  └─ Subnet A: 10.0.1.0/24  → EC2 실행 위치
  └─ Subnet B: 10.0.2.0/24  → ALB 실행 위치
즉, 서브넷이 없으면 EC2나 ALB 자체를 실행할 수 없습니다.

✅ 2. 왜 서브넷이 2개 이상 필요하냐? (특히 ALB와 ASG에서)
☑️ ALB는 기본적으로 고가용성(HA)을 요구합니다.
즉, 시스템이 고장나더라도 서비스가 계속 운영되도록 구성하는 것으로 가상 이지만, 실제 물리적으로
분리된 서비스 영역을 확보

ALB는 2개 이상의 가용 영역(AZ) 에 걸쳐 자동으로 인스턴스를 분산시켜야 하기 때문에,
서브넷을 최소 2개 이상(서로 다른 AZ에) 지정해야 합니다.

서브넷을 2개 이상 만들어서 AZ 분산 구성

✅ AZ (Availability Zone) 이란?
하나의 리전(Region) 안에 물리적으로 분리된 데이터 센터 묶음
예: 서울 리전(ap-northeast-2)에는 ap-northeast-2a, 2b, 2c 가 있음

ap-northeast-2a, 2b, 2c는 서울 리전(ap-northeast-2)에 속한 서로 다른 가용영역(AZ, Availability Zone)이며, 실제로는 물리적으로 분리된 IDC(데이터 센터)입니다.

## 서브넷 구성
aws ec2 create-subnet --vpc-id vpc-0ecdd43bad4b17796 --cidr-block 10.0.1.0/24 --availability-zone ap-northeast-2a
aws ec2 create-subnet --vpc-id vpc-0ecdd43bad4b17796 --cidr-block 10.0.2.0/24 --availability-zone ap-northeast-2c

## 구성확인
![alt text](image-13.png)

## 인터넷 게이트웨이 구성
aws ec2 create-internet-gateway
## 결과
{
    "InternetGateway": {
        "Attachments": [],
        "InternetGatewayId": "igw-027334beabf4ebda5",
        "OwnerId": "086015456585",
        "Tags": []
    }
}

## 아직 사용 전인 상태
![alt text](image-14.png)

## 게이트웨이를 VPC 에 매핑
aws ec2 attach-internet-gateway --internet-gateway-id igw-027334beabf4ebda5 --vpc-id vpc-0ecdd43bad4b17796

## 매핑 상태
![alt text](image-15.png)

