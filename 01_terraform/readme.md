# 01_terraform — Terraform 개념과 Provider

Terraform의 동작 구조와 provider 시스템을 이해하는 이론 단계입니다.

## 학습 목표

- .tf 코드가 실제 클라우드 API 호출로 변환되는 구조를 설명할 수 있다
- `required_providers`와 `provider` 블록의 역할을 구분할 수 있다
- 버전 제약(`~> 5.0`)의 의미와 필요성을 설명할 수 있다
- `terraform init`이 하는 일과 Registry 역할을 설명할 수 있다
- init → plan → apply → destroy 워크플로우와 state의 역할을 설명할 수 있다

## 핵심 내용

- Terraform Core + provider 아키텍처
- required_providers / provider 블록
- 버전 제약 연산자
- init → Registry → .terraform/
- 워크플로우 5단계와 state 생명주기
- state와 잠금 파일

## 이론적 배경

Terraform은 코어와 provider로 분리된 구조입니다. 코어는 .tf 파싱·의존성 그래프·state 관리만 담당하고, AWS API 호출 같은 실제 작업은 전부 provider 플러그인이 수행합니다. 같은 문법으로 AWS·GCP·Kubernetes까지 관리할 수 있는 이유입니다.

## 실습

```bash
terraform init                    # provider 다운로드 → .terraform/, lock 파일 생성
terraform providers               # 설치된 provider 버전 확인
terraform plan                    # 생성 예정 리소스 미리보기
terraform apply                   # VPC 1개 생성 — 승인 입력
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock]' --output table  # AWS에서 확인
terraform state show aws_vpc.hello_vpc   # state에 기록된 실제 리소스 속성
terraform output                  # 03_outputs.tf의 출력값 — vpc_id 등
terraform destroy                 # 삭제 → state도 비워짐
```

- `terraform init` 후 `.terraform/` 디렉터리와 `.terraform.lock.hcl` 확인
- lock 파일을 텍스트 에디터로 열어 버전 고정 내용 확인
- `terraform init -upgrade`로 버전 범위 내 업그레이드 동작 비교
- apply 후 `terraform.tfstate`를 열어 실제 리소스 ID·속성이 기록된 것 확인

## 소스 구조

```text
01_terraform/
├── readme.md           # 이 문서
├── 01_provider.tf      # required_providers + provider 예제
├── 02_vpc.tf           # 생성/삭제 체험용 최소 VPC (무료)
├── 03_outputs.tf          # apply 후 출력되는 vpc_id·vpc_cidr
└── slides/             # 이론 슬라이드 12장 (s01~s12)
```

## 파일·디렉터리 역할

| 경로 | 역할 |
| --- | --- |
| `01_provider.tf` | terraform 블록 + provider "aws" 설정 |
| `02_vpc.tf` | apply/destroy 체험용 `aws_vpc.hello_vpc` |
| `03_outputs.tf` | `terraform output` 조회 대상 — 이후 단계의 출력 예제 |
| `slides/` | s01~s11 슬라이드 — 이론 7 + 워크플로우 2 + 복습 2 |
| `.terraform/` | init이 다운로드한 provider (커밋 금지) |
| `.terraform.lock.hcl` | provider 버전·해시 잠금 (커밋 대상) |

## 단계 간 연결

여기서 배운 provider 개념이 `02_practice`의 실제 .tf 파일에 그대로 적용됩니다 — `01_provider.tf`가 각 step 디렉터리에 복사되어 있습니다.

## 산출물

- required_providers 블록의 의미를 설명할 수 있다
- init 후 생성되는 파일들의 역할을 안다
- apply → state 기록 → destroy의 최소 사이클을 직접 경험한다

## 완료 기준

- [ ] provider와 코어의 역할 분담을 설명할 수 있다
- [ ] `~> 5.0`이 허용하는 버전 범위를 말할 수 있다
- [ ] lock 파일을 커밋해야 하는 이유를 안다
- [ ] state에 무엇이 기록되고 언제 비워지는지 안다
