# 02_practice — Terraform 실습 (AWS 인프라 구축)

VPC부터 RDS·EKS까지 단계별 디렉터리로 나눠 apply하는 실습 단계입니다.

## 학습 목표

- 단계별 독립 state로 인프라를 층별로 구축할 수 있다
- `terraform_remote_state`로 하위 단계 출력을 참조할 수 있다
- apply 중 발생하는 실제 오류(키페어·버전·고아 리소스)를 진단·해결할 수 있다
- AWS CLI로 생성 결과를 검증할 수 있다

## 핵심 내용

- step1_network: VPC·서브넷·IGW·NGW·라우팅 + outputs
- step2_compute: SG·EC2·RDS (remote_state로 step1 참조)
- step3_eks: EKS·노드그룹·ECR
- step4_alb: Route53·ACM·ALB (작성 예정)
- destroy는 역순: step4 → step3 → step2 → step1

## 이론적 배경

State 분리(State decomposition)는 계층별 라이프사이클이 다를 때 쓰는 정식 패턴입니다. 네트워크는 오래 유지하고 컴퓨트는 자주 바꾸는 구조에서, 각 단계가 독립 state를 가지면 한 단계의 변경이 다른 단계를 건드리지 않습니다. `terraform_remote_state` 데이터 소스가 상위 단계의 outputs를 읽어 연결 고리를 만듭니다.

## 실습

```bash
cd step1_network && terraform init && terraform apply
./check.sh                                  # → report.html 이 단계만 검증
cd ../step2_compute && terraform init && terraform apply
./check.sh                                  # → SG·EC2·RDS 확인
cd ../step3_eks && terraform init && terraform apply
./check.sh                                  # → EKS·노드그룹·ECR 확인
```

```bash
./check.sh   # 루트에서 실행하면 전체 리소스 조회 → report.html 생성
```

- 각 step의 `check.sh`는 그 단계의 `state` + AWS 실제 리소스만 조회

```bash
terraform destroy   # 각 단계 디렉터리에서 역순 실행
```

1. step1에서 네트워크 생성 후 outputs 값 확인
2. step2 apply 시 remote_state가 step1 출력을 읽는지 plan으로 확인
3. `./check.sh` 실행해 생성된 리소스가 HTML로 나오는지 확인
4. 실습 후 반드시 역순 destroy (과금 방지)

## 소스 구조

```text
02_practice/
├── readme.md
├── check.sh              # 전체 리소스 점검 → report.html
├── step1_network/        # VPC·서브넷·IGW·NGW·라우팅 + outputs.tf + check.sh
├── step2_compute/        # SG·EC2·RDS + 00-remote-state.tf + check.sh
├── step3_eks/            # EKS·노드그룹·ECR + 00-remote-state.tf + check.sh
├── step4_alb/            # Route53·ACM·ALB (빈 파일 — 작성 예정) + check.sh
└── slides/               # 실행 방법 슬라이드 11장
```

## 파일·디렉터리 역할

| 경로 | 역할 |
| --- | --- |
| `stepN/01_provider.tf` | 각 단계 독립 provider 설정 |
| `step1_network/outputs.tf` | vpc_id·subnet_id 출력 — 상위 단계 연결 고리 |
| `stepN/00-remote-state.tf` | step1 state 참조 + locals 래핑 |
| `check.sh` | 전체 리소스 점검 → HTML 리포트 |
| `stepN/check.sh` | 해당 단계 리소스만 검증 → HTML 리포트 |
| `terraform.tfstate` | 각 step 디렉터리에 독립 존재 — 절대 커밋 금지 |

## 단계 간 연결

`03_real`은 이 실습을 모듈·변수 구조로 리팩터링한 버전입니다 — `origin/`에 이 단계 원본이 보관되어 비교할 수 있습니다.

## 산출물

- 4단계로 나뉜 state 기반 인프라
- check.sh로 생성한 결과 리포트

## 완료 기준

- [ ] 각 단계가 독립 state를 갖는 이유를 설명할 수 있다
- [ ] remote_state 참조 구조를 이해한다
- [ ] apply 오류 시 state와 AWS 실제 상태를 대조해 진단할 수 있다
- [ ] destroy 역순 규칙을 안다
