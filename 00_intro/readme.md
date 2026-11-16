# 00_intro — 과정 개요 (IaC와 Terraform)

Terraform으로 AWS 인프라를 코드로 관리하는 학습 과정의 전체 흐름을 소개하는 단계입니다.

## 과정 목표

- IaC(Infrastructure as Code)의 개념과 필요성을 이해한다
- Terraform의 동작 방식과 워크플로우(init → plan → apply → destroy)를 익힌다
- AWS 실습을 통해 실제 인프라를 코드로 구축·검증·삭제한다
- 변수·모듈화로 실전 표준 레이아웃까지 확장한다

## 단계 구성

- `00_intro` — 과정 개요, 전체 구조도·IaC 개념 슬라이드 (이 단계)
- `01_terraform` — Provider·state·HCL 블록·워크플로우 이론
- `02_practice` — 번호 순서로 apply하는 입문 AWS 실습 (단일 state)
- `03_real` — variables/outputs 분리·모듈화된 실전 레이아웃 (EKS·RDS 포함)
- `04_https` — remote_state로 연결하는 선택 HTTPS 확장
- `10_cicd` — 저장소 계층+GitHub 인프라 파이프라인 (main → plan·승인·apply)
- `11_app_pipeline` — GitHub dev 브랜치 → docker·ECR·EKS 앱 배포

번호 순서가 진행 순서이며, 11은 10의 출력을 remote_state로 읽습니다.
destroy는 역순(11→10) — 상세 구조는 `slides/`의 구조도 슬라이드를 보세요.

## 학습 흐름

1. 개념(00·01): IaC와 Terraform의 동작 원리 이해
2. 실습(02·03): 네트워크→컴퓨트→EKS 구축, 변수·모듈로 실전 레이아웃
3. 선택(04): 별도 state로 HTTPS 확장 — remote_state 첫 경험
4. GitOps(10·11·12): 저장소 계층 → 인프라 파이프라인 → 앱 파이프라인

## 주요 개념

- **IaC**: 인프라를 코드로 선언해 버전 관리·자동화·재현을 가능하게 하는 방식
- **선언적 vs 명령적**: 결과 상태를 선언(Terraform) vs 실행 절차를 기술(스크립트·Ansible)
- **프로비저닝**: 선언된 자원을 실제 클라우드에 생성·배치하는 과정

## Terraform 워크플로우

```bash
terraform init       # provider 다운로드·초기화
terraform validate   # 문법·참조 검증
terraform plan       # 변경 예정 미리보기
terraform apply      # 실제 적용
terraform destroy    # 전체 삭제
```

## 도구 비교

| 구분 | Terraform | Ansible |
| --- | --- | --- |
| 목적 | 인프라 프로비저닝 | 구성 관리·배포 |
| 방식 | 선언적 (최종 상태) | 명령적 (실행 절차) |
| 상태 관리 | state 파일로 추적 | 상태 비관리 (멱등성) |
| 언어 | HCL | YAML |

## 디렉터리 구조

```text
aws-tf/
├── index.html          # 루트 포털 (이 파일에서 각 단계로 이동)
├── 00_intro/           # 개요 슬라이드 8장 + 통합 용어집
├── 01_terraform/       # 이론 슬라이드 12장 + provider/VPC 예제
├── 02_practice/        # 네트워크+컴퓨트 실습 .tf + 슬라이드 17장 + check.sh
├── 03_real/            # 실전 표준 레이아웃 + 슬라이드 9장 + origin/ 비교본
├── 04_https/           # ACM+HTTPS 확장 — remote_state로 03 참조
├── 10_cicd/            # 저장소+GitHub 인프라 파이프라인 — main 브랜치
├── 11_app_pipeline/    # dev 브랜치 — 앱 배포 파이프라인
└── .agents/            # 강사용 템플릿·생성기·로그 (학생 배포 제외)
```

## 주의사항

- 실습은 실제 AWS 계정에 리소스를 생성합니다 — NAT Gateway·EC2·RDS·EKS는 **과금**됩니다
- `terraform destroy`로 실습 후 정리하세요 (역순: step4 → step1)
- AWS 태그(`Name`)와 Terraform 리소스 이름은 별개입니다 — 코드 식별자는 언더스코어

## 용어집

전 단계 용어 **81개**를 자음순으로 정리한 통합 용어집:

- [`glossary/index.html`](glossary/index.html) — 단계별 탭으로 보는 용어집 포털
- [`glossary.md`](glossary.md) — 원본 마크다운

단계 구성: 0단계 IaC 개념 · 1단계 Provider·워크플로우 · 2단계 AWS 리소스·실습 · 3단계 변수·실전 패턴

## SVG 슬라이드

| 파일 | 내용 |
| --- | --- |
| s01-title | 타이틀 |
| s02-iac | IaC 개념 (선언적 vs 명령적) |
| s03-provisioning | 프로비저닝 대상 자원 |
| s04-terraform | Terraform 소개 + HCL 예시 |
| s05-workflow | init → apply 워크플로우 |
| s06-benefits | 장점 5가지 |
| s07-vs-ansible | Ansible 비교 표 |
| s08-summary | 정리 |
