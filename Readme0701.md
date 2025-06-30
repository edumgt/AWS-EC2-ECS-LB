## AMI 퍼블릭 공유
ami-0594aa3b1a9017b0a

## AMI 공유를 위한 설정 변경
![alt text](image-88.png)
![alt text](image-89.png)

## 아래에서 관리 클릭
![alt text](image-90.png)
## 아래에서 체크 없애고, 즉, 신규 공유 차단 을 해제 하고, 업데이트
![alt text](image-91.png)

## 다시 AMI 정보 중 AMI 권한 편집
![alt text](image-92.png)

## 처음에 비활성화 되었으나 공유 가능하게 변경됨
![alt text](image-93.png)

## AMI 공유에서 AMI 사용을 위한 검색
![alt text](image-94.png)

## 커뮤니티 선택 후 ami-0594aa3b1a9017b0a 으로 찾기
![alt text](image-95.png)

## AMI 선택 후 AMI 로 템플릿 생성
![alt text](image-96.png)

## 이미 AMI 선택 한 상황으로 이름, 설명 등 입력
![alt text](image-97.png)

## VPC 생성 - 네트웍 구성이 복잡하고, 어렵다 보니 추천 설정이 있습니다.
![alt text](image-98.png)

## 위에서 CIDR 블록은 권장하는대로 16 사용 즉, 10.0.0.0/16
![alt text](image-99.png)

## 위의 작업 완료 후 VPC 보기 클릭
![alt text](image-100.png)

## 퍼블릭 액세스 차단을 비활성화 하였으므로, 퍼블릭 액세스가 된다는 의미
![alt text](image-101.png)

## 물리적으로 VM 을 공유하는 하드웨어 사용을 허용 - 다른 옵션에서 보안상 물리적으로 완전 다른 서버 구성을 의미
![alt text](image-102.png)

## 시작 템플릿 만들기 - AWS 추천, 조언 보면서 작업
![alt text](image-103.png)

## AMI 위의 AMI 사용 또는 AMI 만들기를 통해 각자 만든 AMI 사용
## 중간의 인스탄스 유형에 대해 조언 클릭
![alt text](image-104.png)
## Advanced Param 을 이용한 선택
![alt text](image-105.png)

## 추천 받는 EC2 
![alt text](image-106.png)

## 서버 종류 설명
AWS의 M7g, M6g, C7g, C6g 인스턴스는 모두 Graviton 시리즈 (ARM 아키텍처) 기반의 인스턴스입니다. 아래에 각 시리즈의 특징과 차이를 정리해드릴게요.

✅ 공통점: Graviton 기반
모두 AWS Graviton2 (M6g, C6g) 또는 Graviton3 (M7g, C7g) 프로세서를 사용
ARM 아키텍처 기반 → x86 대비 더 낮은 비용, 더 높은 성능/Watt
EBS 최적화 및 ENA (Elastic Network Adapter) 지원
Nitro 시스템 기반 (고성능, 고보안 가상화)

📘 M 시리즈: 범용 인스턴스
✅ M6g – Graviton2 기반 (2세대)
출시 시기: 2020년
CPU: AWS Graviton2 (ARM Neoverse N1, 64비트)
용도: 범용 워크로드 (웹 서버, 앱 서버, 컨테이너, 마이크로서비스, 캐시 등)
vCPU 대비 메모리 비율: 1 vCPU당 4 GiB

✅ M7g – Graviton3 기반 (3세대)
출시 시기: 2023년
CPU: AWS Graviton3 (ARM Neoverse V1)
성능: M6g 대비 최대 25% 더 높은 컴퓨팅 성능, 메모리 대역폭 50% 증가
더 높은 에너지 효율, 향상된 암호화 및 머신러닝 워크로드 성능
용도: M6g와 동일하지만, 더 높은 성능 필요 시 선택

📗 C 시리즈: 컴퓨팅 최적화
✅ C6g – Graviton2 기반
CPU: AWS Graviton2
용도: 고성능 컴퓨팅 집중 워크로드
웹 서버, 고성능 컴퓨팅(HPC), 네트워크 장비 시뮬레이션, 배치 처리, 게임 서버
vCPU 대비 메모리 비율: 1 vCPU당 2 GiB

✅ C7g – Graviton3 기반
CPU: AWS Graviton3
성능: C6g 대비 최대 25% 성능 향상
네트워크 대역폭과 패킷 처리량 향상
용도: 고성능 컴퓨팅 중에서도 최신 CPU/네트워크 성능이 필요한 경우


## 종류 목록
| 인스턴스 | 프로세서      | 용도           | 성능 세대 | 메모리 비율       | 출시   |
| ---- | --------- | ------------ | ----- | ------------ | ---- |
| M6g  | Graviton2 | 범용           | 2세대   | 1 vCPU당 4GiB | 2020 |
| M7g  | Graviton3 | 범용 (고성능)     | 3세대   | 1 vCPU당 4GiB | 2023 |
| C6g  | Graviton2 | 컴퓨팅 집중       | 2세대   | 1 vCPU당 2GiB | 2020 |
| C7g  | Graviton3 | 컴퓨팅 집중 (고성능) | 3세대   | 1 vCPU당 2GiB | 2023 |

## 선택 가이드
일반 서버, 백엔드, 마이크로서비스: M6g, M7g
고성능/계산 집중형 처리: C6g, C7g
최신 ARM 성능 필요: M7g, C7g (Graviton3 기반)

## 현재 AMI 가 M6g 를 지원하지 않아 선택 안됨, 유사 기종 - M6i 선택
![alt text](image-107.png)

## 해당 key 파일, pem 파일 공유했습니다.

## VPC 만들면서 보안그룹 만들어졌고 사용 합니다.
![alt text](image-109.png)
![alt text](image-110.png)

## 그외 별다른 설정 없습니다. 템플릿 생성
![alt text](image-111.png)

## 템플릿 생성 후 바로 다음 단계 추천이 나옵니다.
![alt text](image-112.png)
## 그중에 Autoscaling Group 을 클릭합니다.
![alt text](image-113.png)

## 시작템플릿을 자동 셋팅함. Autoscaling 그룹이름 지정
![alt text](image-114.png)


## 6월30일 테스트 중 AMI 가 기존 VPC 를 선택했던 정보가 맞지 않은 오류가 있었던 같아 이부분을 주의깊게 테스트함
![alt text](image-115.png)
## 새로 만든 VPC 사용
![alt text](image-116.png)
## 자동생성된 서브넷 4개 중에 3개 선택 - public 포함
![alt text](image-117.png)

## 기본 라우팅 자동 생성
![alt text](image-118.png)

## 기본라우팅
AWS 로드 밸런서에서 말하는 "기본 라우팅(기본 전달 대상, Default Routing / Default Target Group)"은 로드 밸런서가 어떤 요청을 특정 규칙에 일치하지 않을 때 어디로 전달할 것인지를 지정하는 기능입니다.

기본 라우팅이란?
🔹 정의
라우팅 규칙에 일치하지 않는 요청이 들어왔을 때,
지정된 **기본 대상 그룹(Default Target Group)**으로 요청을 전달합니다.

로드 밸런서 도메인: myapp.example.com

[라우팅 규칙]
- /api/*  → Target Group A
- /admin/* → Target Group B
이때 사용자가 /help로 접속하면 /api/*나 /admin/*과 일치하지 않음 →
→ 이 요청은 **기본 대상 그룹 (예: Target Group C)**으로 전달됩니다.

## 해당 없을 경우 처리 내역
| 요소                | 설명                                  |
| ----------------- | ----------------------------------- |
| **로드 밸런서(ALB)**   | HTTP 요청을 받아 라우팅 규칙 확인               |
| **리스너(Listener)** | 요청을 포트별로 받고 규칙 적용 (예: 80/443)       |
| **리스너 규칙**        | 경로/호스트 기반 규칙 (if /api/\* then TG-A) |
| **기본 대상 그룹**      | 위 규칙에 해당하지 않을 때 요청을 보낼 대상           |

## 다음 단계
![alt text](image-119.png)
즉, Auto Scaling Group을 생성할 때, 시작 시 몇 개의 EC2 인스턴스를 자동으로 실행할지 설정하는 값입니다

## 사용자 정의
![alt text](image-120.png)

## 이 범위는 현재 그룹의 크기 조정 한도 내에 있습니다. 의 녹색 메시지 내에서 설정

## 이후 별다른 설정 없이 생성
![alt text](image-121.png)

## EC2 목록에서 VM 인스탄스 실행 중 확인
![alt text](image-122.png)

## AutoScaling 목록 중 클릭하여 대상 인스탄스 보기
![alt text](image-123.png)
![alt text](image-124.png)

## EC2 대시보드에서 로드밸런서 수치 확인
![alt text](image-125.png)

## 목록확인
![alt text](image-126.png)

## 로드밸런서의 기능확인
![alt text](image-127.png)

## 인스탄스 VM 의 종류가 문제인지 파악을 위해 시작 템플릿 클릭하여, 버젼 수정
## 또는 생성 AMI 의 VPC 가 다른 문제인지?
![alt text](image-128.png)

## 템플릿의 새버젼 생성
![alt text](image-129.png)

## t3.medium 선택 - 6월30일 테스트 중 t2... 일부 서버가 AZ 중 ac 영역에서 오류 나는 듯.
![alt text](image-130.png)

## 새로 생성한 VPC 연동 SG 선택
![alt text](image-131.png)

## 새로 생성한 템플릿의 수정 버젼 2를 기본으로 변경
![alt text](image-132.png)

## 화면 리프레시 중 오류 보일 수 있음 - 무시 - 로그인 세션 전체 삭제 되는 경우 있음
![alt text](image-133.png)

## M6i 서버 중지
## 버젼 2의 템플릿으로 서버 재기동 중 필요에 따라 강제 리프레시
![alt text](image-134.png)

## 인스탄스 재기동은 확인
![alt text](image-135.png)

## Autoscaling 에서는 healthy 로 보고 있고, Load Balancer 에서는 unhealthy 로 보고 있어서, 직접 서버 접속을 위한 탄력적 IP 부여
![alt text](image-136.png)
즉, 공인 IP 를 VM 에 매핑하여 서버 접속, 다른 서버 접속의 다양한 방법이 있으나, 공인 IP 부여 방법도 체크

![alt text](image-137.png)
## 공인 IP 받음
![alt text](image-138.png)

## IP 상세
![alt text](image-139.png)
![alt text](image-140.png)

## 연결할 VM 확인
![alt text](image-141.png)
## 해당 VM 에 공인 IP 부여 확인
## 연결 시도
![alt text](image-142.png)
## SSH 연결 거부

## ssh 접속 시도
PS C:\edumgt-java-education\AWS_EC2_AUTO> ssh -i "MyNginXKey.pem" root@ec2-3-36-229-4.ap-northeast-2.compute.amazonaws.com
ssh: connect to host ec2-3-36-229-4.ap-northeast-2.compute.amazonaws.com port 22: Connection timed out

