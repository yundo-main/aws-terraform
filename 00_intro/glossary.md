# 용어 정리 — 전체 단계 통합 용어집

00~03단계 학습 자료에서 사용하는 핵심 용어를 단계별로 모았다.

## 단계별 용어

### 0단계 · 과정 개요 — IaC와 Terraform

| 용어 | 설명 |
| --- | --- |
| Ansible vs Terraform | 구성 관리(명령적) vs 프로비저닝(선언적) |
| CloudFormation | AWS 전용 IaC 서비스 |
| IaC | Infrastructure as Code — 인프라를 코드로 선언·관리 |
| Kubernetes Manifest | K8s 리소스를 YAML로 선언하는 방식 |
| Terraform | HashiCorp의 멀티 클라우드 IaC 도구 |
| 멀티 클라우드 | AWS·GCP·Azure 등을 같은 도구로 관리 |
| 멱등성 | 여러 번 실행해도 같은 결과 — 선언적 도구의 특징 |
| 명령적 | 실행 절차를 직접 기술 — 스크립트 방식 |
| 선언적 | 원하는 최종 상태만 기술 — 절차는 도구가 결정 |
| 프로비저닝 | 클라우드 자원을 실제로 생성·배치하는 과정 |

### 1단계 · Terraform 개념 — Provider와 워크플로우

| 용어 | 설명 |
| --- | --- |
| .terraform.lock.hcl | provider 버전·해시 잠금 파일 — 커밋 대상 |
| .terraform/ | init이 다운로드한 provider 플러그인 디렉터리 |
| HCL | HashiCorp Configuration Language — .tf 파일 문법 |
| apply | 계획을 실제 인프라에 반영하는 명령 |
| data 소스 | 생성하지 않고 기존 리소스를 읽는 블록 |
| destroy | state가 관리하는 리소스를 전부 삭제 |
| init | provider 다운로드·작업 디렉터리 초기화 |
| output 블록 | apply 결과를 콘솔에 출력 — terraform output으로 조회 |
| plan | 실행 전 변경 예정을 미리 보여주는 단계 |
| provider | 클라우드 API를 Terraform 리소스로 번역하는 플러그인 |
| provider 블록 | 리전·인증 등 실제 접속 설정 |
| registry | provider·모듈을 배포하는 공개 저장소 |
| required_providers | 사용할 provider와 버전을 고정하는 블록 |
| resource | 생성할 인프라 객체의 선언 블록 |
| state | 실제 인프라와 코드의 매핑을 기록한 상태 파일 |
| terraform output | outputs에 선언된 값만 모아 표시 |
| terraform state show | state에 기록된 리소스 속성 조회 |
| terraform.tfstate | 현재 관리 중인 리소스 상태가 저장되는 파일 |
| validate | 문법·참조 오류를 실행 전 검사 |
| version constraint | ~> 5.0 같은 provider 버전 범위 지정 |
| 워크플로우 | write → init → plan → apply → destroy 순서 |
| 의존성 그래프 | 리소스 참조 관계로 실행 순서를 자동 결정 |

### 2단계 · Terraform 실습 — AWS 인프라 구축

| 용어 | 설명 |
| --- | --- |
| -target | apply 대상을 특정 리소스로 제한 — 일상 사용 비추천 |
| Availability Zone | 리전 내 물리적 데이터센터 구역 |
| CIDR | IP 대역 표기 — 10.200.0.0/16 |
| EC2 | AWS 가상 서버 — 여기서는 배스천 |
| ECR | Elastic Container Registry — 컨테이너 이미지 저장소 |
| EIP | Elastic IP — 고정 공인 IP (NGW에 연결) |
| EKS | 관리형 Kubernetes — 컨트롤플레인은 AWS 관리 |
| IAM role | AWS API 권한을 리소스에 부여하는 역할 |
| IGW | Internet Gateway — VPC ↔ 인터넷 연결 |
| NGW | NAT Gateway — 프라이빗 서브넷의 외부 출구 (과금) |
| RDS | 관리형 관계형 DB — 여기서는 MariaDB |
| VPC | Virtual Private Cloud — 격리된 가상 네트워크 |
| check.sh | step별 생성 리소스를 AWS CLI로 검증 → HTML 리포트 |
| kubectl | Kubernetes 클러스터 조작 CLI |
| outputs | 다음 단계·사용자에게 노출할 값 |
| terraform import | 기존 AWS 리소스를 state로 편입 |
| terraform_remote_state | 다른 state의 outputs를 읽는 데이터 소스 |
| 고아 리소스 | state 없이 AWS에만 남은 리소스 — import 또는 삭제 필요 |
| 노드그룹 | EKS 워커 EC2 묶음 — 오토스케일링 범위 설정 |
| 단계별 디렉터리 | state를 나눈 실행 구조 — 10_backend·11_infra_pipeline·12_app_pipeline이 사례 |
| 라우팅 테이블 | 서브넷 트래픽의 목적지 규칙 |
| 리소스 이름 | 코드 식별자 — 언더스코어 권장 (태그와 별개) |
| 배스천 | 프라이빗망 진입용 경유 서버 |
| 보안 그룹 | 인스턴스 수준 가상 방화벽 |
| 서브넷 | VPC 안의 IP 대역 분할 — 퍼블릭/프라이빗 |
| 서브넷 그룹 | RDS가 배치될 서브넷 묶음 |
| 키페어 | EC2 SSH 접속용 공개키/개인키 쌍 |
| 파라미터 그룹 | RDS 엔진 설정 모음 |

### 3단계 · Terraform 실전 — 변수·모듈 구조

| 용어 | 설명 |
| --- | --- |
| -var / -var-file | apply 시 변수 값을 주입하는 옵션 |
| DRY | 반복하지 않는 원칙 — 변수·모듈로 달성 |
| TF_VAR_ 접두사 | 환경변수로 변수를 전달하는 방식 |
| count | 리소스를 조건부·반복 생성하는 메타 인자 |
| default_tags | provider 레벨 공통 태그 — 모든 리소스에 자동 적용 |
| dynamic 블록 | 반복되는 중첩 블록을 for_each로 생성 |
| for_each | 맵·집합을 순회하며 리소스·블록 생성 |
| locals | 반복 계산 값에 이름을 붙이는 로컬 변수 |
| outputs.tf | 출력 선언 파일 |
| sensitive | 출력에서 값을 가리는 변수 속성 — 비밀번호에 필수 |
| tfvars | 변수 값을 파일로 전달 — .gitignore 대상 |
| var.xxx | 변수 참조 문법 |
| variable 블록 | 타입·기본값·설명을 가진 매개변수 선언 |
| variables.tf | 입력 변수 선언 파일 |
| workspace | 같은 코드의 별도 state — 환경 복제용, 스텝과 무관 |
| 단일 state | 모듈 방식 — 한 번의 apply로 전체 관리 |
| 루트 모듈 | 실행 디렉터리의 .tf 파일 집합 |
| 리팩터링 | 동작 유지하며 구조만 개선 |
| 모듈 | 재사용 가능한 리소스 묶음 — main.tf에서 호출 |
| 버전 고정 | terraform·provider 버전을 명시해 재현성 확보 |
| 표준 레이아웃 | versions/providers/variables/main/outputs 파일 분리 |
| 하드코딩 | 값을 코드에 직접 박는 방식 — 변수화 대상 |
| 환경 분리 | dev/stage/prod를 변수·디렉터리로 구분 |

### 4단계 · CI/CD — AWS 네이티브 파이프라인

| 용어 | 설명 |
| --- | --- |
| CI/CD | 코드 변경을 자동 빌드·테스트·배포하는 파이프라인 |
| CodeBuild | 관리형 빌드 — buildspec.yml로 실행 명령 정의 |
| CodeCommit | AWS 관리형 git 저장소 — push가 트리거 |
| CodePipeline | 단계 오케스트레이션 — Source→Build→Approve→Deploy |
| DynamoDB lock | state 동시 수정을 막는 잠금 테이블 |
| ECR 리포지토리 | 컨테이너 이미지 저장소 — docker push 대상 |
| EventBridge | push 같은 이벤트를 감지해 파이프라인 실행 |
| GitOps | git push가 인프라 변경 트리거가 되는 운영 방식 |
| S3 backend | state를 S3에 저장 — CI·팀 공유의 기본 |
| artifact | 단계 간 전달되는 산출물 — plan_out의 tfplan |
| aws-auth | EKS에 IAM 역할을 kubectl 권한으로 매핑하는 ConfigMap |
| buildspec.yml | CodeBuild 실행 스크립트 — install/build/artifacts |
| imageDetail.json | 빌드→배포로 이미지 URI를 전달하는 artifact |
| kubectl set image | 실행 중 deployment의 이미지를 교체하는 명령 |
| manual approval | plan과 apply 사이 사람 승인 게이트 |
| migrate-state | 로컬 state를 S3 backend로 이전하는 init 옵션 |
| prevent_destroy | 리소스 삭제를 차단하는 lifecycle 가드 |
| privileged_mode | CodeBuild에서 docker 데몬을 쓰기 위한 플래그 |
| rollout status | 배포 완료를 기다리는 kubectl 명령 |
| 최소권한 | 필요한 작업만 허용하는 IAM 원칙 |

---

총 103개 용어 · 5개 단계
