# 02_practice — Terraform 실습 (AWS 인프라 구축)

VPC부터 RDS까지 하나의 디렉터리(단일 state)로 apply하는 실습 단계입니다. 파일 번호가 리소스 생성 순서이자 읽는 순서입니다. EKS·ALB는 03_real에서 확장됩니다.

## 학습 목표

- 단계별 독립 state로 인프라를 층별로 구축할 수 있다
- 같은 state 안에서 리소스가 서로를 직접 참조하는 의존 그래프를 읽을 수 있다
- apply 중 발생하는 실제 오류(키페어·버전·고아 리소스)를 진단·해결할 수 있다
- AWS CLI로 생성 결과를 검증할 수 있다

## 핵심 내용

- 01: provider·버전 고정
- 02~06: 네트워크 (VPC·서브넷·IGW·NGW·라우팅)
- 07~09: 컴퓨트 (SG·EC2 배스천·RDS)
- destroy는 apply의 역순으로 자동 계산됨

## 이론적 배경

단일 state에서는 모든 리소스가 하나의 의존 그래프가 됩니다 — `aws_subnet`의 `vpc_id = aws_vpc.x.id` 같은 직접 참조가 연결 고리를 만들고, Terraform이 생성 순서를 자동으로 계산합니다. 계층별 state 분리(remote_state)는 10_cicd에서 다룹니다.

## 실습

```bash
terraform init
terraform plan      # 22개 리소스 생성 계획 — 의존 순서 확인
terraform apply     # 전체 생성 (RDS는 수 분 소요)

./check.sh          # terraform state + AWS 실체 대조 → report.html

terraform destroy   # 전체 삭제
```

1. plan 출력에서 리소스 생성 순서(의존 그래프) 확인
2. apply 후 `terraform output`으로 접속 정보 확인
3. check.sh 리포트로 state ↔ AWS 실체 대조
4. 실습 후 반드시 역순 destroy (과금 방지)

## 소스 구조

```text
02_practice/
├── readme.md
├── check.sh              # 전체 리소스 점검 → report.html
├── 01-provider.tf        # provider·버전 고정
├── 02-vpc.tf ~ 06        # 네트워크 계층
├── 07-sg ~ 09-rds.tf     # 컴퓨트 계층
├── 10-outputs.tf       # 전체 출력
└── slides/               # 실행 방법 슬라이드 17장
```

## 파일·디렉터리 역할

| 경로 | 역할 |
| --- | --- |

## 단계 간 연결

`03_real`은 이 실습을 모듈·변수 구조로 리팩터링한 버전입니다 — `origin/`에 이 단계 원본이 보관되어 비교할 수 있습니다.

## 산출물

- 4단계로 나뉜 state 기반 인프라
- check.sh로 생성한 결과 리포트

## 완료 기준

- [ ] 각 단계가 독립 state를 갖는 이유를 설명할 수 있다
- [ ] 리소스 간 직접 참조(`aws_vpc.x.id`)로 의존 그래프가 만들어지는 걸 이해한다
- [ ] apply 오류 시 state와 AWS 실제 상태를 대조해 진단할 수 있다
- [ ] destroy 역순 규칙을 안다
