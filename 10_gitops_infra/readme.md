# 10_gitops_infra — GitHub 인프라 CI/CD 파이프라인

한 디렉터리에서 **저장소 계층 + 파이프라인**을 함께 만듭니다 — state는 로컬 파일입니다.

`.tf` 코드 push → 자동 plan → 수동 승인 → apply가 돌아가는 파이프라인입니다.
소스는 **GitHub 리포** — CodeConnections로 연결되어 `git push origin main`이 곧 트리거입니다.
artifact 버킷·tfstate 버킷·lock 테이블도 같은 디렉터리(`02-state.tf`)가 만듭니다.

## 만드는 리소스 (15개)

저장소 계층 (02-state.tf): tfstate 버킷(+버저닝·암호화·공개차단) · DynamoDB lock · artifact 버킷 — 7개

파이프라인 (main.tf):

| 리소스 | 역할 |
| --- | --- |
| `aws_codestarconnections_connection.github` | GitHub 연결 — 소스·트리거 역할 (콘솔 승인 1회 필요) |
| `aws_iam_role.codebuild` + admin | 빌드 실행 역할 (11_gitops_app도 공용) |
| `aws_codebuild_project.plan/apply` | terraform plan / apply 실행기 |
| `aws_iam_role.pipeline` + 정책 | 파이프라인 실행 역할 (11_gitops_app도 공용) |
| `aws_codepipeline.tf` | Source→Plan→Approve→Apply 4단계 |

## 핵심 포인트

- 이 단계의 state는 **로컬** — `terraform.tfstate` 파일이 버킷·파이프라인 전부를 추적합니다.
- 공용 IAM 역할 2개는 이 단계 소유 — `outputs.tf`로 11_gitops_app에 전달됩니다.
- 소스가 GitHub 리포 전체라 `TF_DIR`(기본 `03_real`)·`buildspec` 경로는 리포 안 위치와 일치해야 합니다.
- 앱 배포 파이프라인(dev 브랜치 기반)은 `11_gitops_app`에서 다룹니다.

## 이론적 배경

로컬 `terraform apply`는 개발자 PC에서 state를 만지지만, 팀·자동화 환경에서는 state를 **S3 backend**에 두고 DynamoDB로 잠급니다. 파이프라인의 CodeBuild는 이 S3 state를 읽어 plan→apply합니다. plan과 apply 사이에 수동 승인을 둬서 "계획 확인 없이 인프라가 바뀌는" 사고를 막습니다.

## 이 파이프라인의 범위

이 단계가 만드는 것은 **인프라 파이프라인**입니다 — `.tf` 코드 변경을 자동 배포합니다.

```text
[인프라 파이프라인]  ← 이 디렉터리가 만드는 것 (main 브랜치 소스)
.tf push → plan → 승인 → apply   (VPC·EKS·RDS 같은 뼈대)

[앱 파이프라인]      ← 11_gitops_app이 만드는 것 (dev 브랜치 소스)
앱 코드 push → docker build → ECR push → EKS 배포
```

---

## 실습 절차 — Step 0부터 Step 8까지

**장면**: 수동 `terraform apply`로 관리하던 03_real 인프라를 GitOps로 전환 —
push만으로 배포되는 구조를 순서대로 만듭니다. 모든 git 명령은 **리포 루트**에서 실행합니다.

### Step 0 — 준비 확인

```bash
# 리포 루트에서
aws sts get-caller-identity     # AWS 자격증명 동작 확인
git remote -v                   # origin = https://github.com/yundo-main/aws-terraform
git status --short              # 커밋 안 된 변경 없는지
```

**전제**: `03_real`이 apply된 상태 (EKS·RDS 존재). 없으면 `cd 03_real && terraform apply` 먼저.

### Step 1 — 저장소 + 파이프라인 생성

```bash
cd 10_gitops_infra
terraform init
terraform apply        # → 15 to add (버킷 7 + 파이프라인 8)
```

**기대 결과**: `Apply complete!` — 로컬에 `terraform.tfstate` 생성.

**확인**:

```bash
terraform output                 # backend_snippet·버킷 이름·역할 arn 확인
ls terraform.tfstate             # 로컬 state 파일 — 이 단계는 S3 backend 안 씀
```

**자주 나는 오류**: `Error creating S3 bucket: BucketAlreadyExists` → 버킷명이 전역 충돌.
`variables.tf`의 버킷 이름 변수를 고유한 값으로 바꾸고 재apply.

### Step 2 — GitHub connection 승인 (수동 1회, 필수)

apply 직후 connection은 `PENDING` — OAuth 악수는 자동화 불가입니다.

1. AWS 콘솔 → **Developer Tools → Connections** (또는 CodePipeline → 설정 → 연결)
2. `<project>-github` 선택 → **Update pending connection**
3. GitHub 로그인 → 앱 설치·승인 → 상태가 `AVAILABLE`로

**확인**:

```bash
aws codeconnections list-connections --query 'Connections[*].[ConnectionName,ConnectionStatus]' --output table
# → <project>-github  AVAILABLE 이어야 함
```

**실패 시**: PENDING 그대로면 파이프라인이 Source에서 영원히 멈춥니다 — 가장 흔한 걸림돌.

### Step 3 — 03_real을 S3 backend로 전환

```bash
# 1) snippet 복사
cd 10_gitops_infra && terraform output -raw backend_snippet

# 2) 03_real/versions.tf의 terraform { } 블록 안에 붙여넣기 — 편집기로 직접 추가
#    backend "s3" { bucket=...  key="03_real/terraform.tfstate"  region=...  dynamodb_table=... }

# 3) 마이그레이션
cd 03_real && terraform init -migrate-state
# → "Do you want to copy existing state to the new backend?" → yes
```

**학습 포인트**: 이 순간부터 state의 진실은 내 PC가 아니라 S3입니다 — CodeBuild와 내가 같은 장부를 봅니다.

**확인**:

```bash
cd 03_real && terraform state list | head        # S3에서 읽히는지
aws s3 ls s3://<tfstate-버킷>/03_real/           # state 파일이 버킷에 있는지
```

### Step 4 — 첫 파이프라인 실행 (push = 트리거)

```bash
# 리포 루트 — 별도 리모트·CI 명령 없이 평소 push가 곧 트리거
git push origin main
```

**관찰** — CodePipeline 콘솔 → `<project>-tf` 파이프라인:

| 단계 | 보이는 것 | 성공 기준 |
| --- | --- | --- |
| Source | 실행 ID가 수동 개입 없이 생성됨 | 단계 초록 |
| Plan | CodeBuild 로그에 `terraform plan` 출력 | `Plan: N to add` 로그 |
| Approve | **파이프라인이 멈춤** | 승인 버튼이 대기 — 알아서 안 넘어감 |
| Apply | `terraform apply tfplan` 로그 | (승인 후에만 실행) |

### Step 5 — 승인 게이트 체험

1. Approve에서 멈춘 상태 그대로 두기 → **Apply가 실행되지 않음을 확인** (게이트가 막는다는 증명)
2. Plan 단계 → CodeBuild 로그 열기 → `Plan: 0 to add` 또는 diff 읽기
3. Approve 카드의 **Review → Approve** 클릭 → Apply 단계 진행

**검증 — 파이프라인이 state를 갱신했다는 증거**:

```bash
cd 03_real && terraform plan
# → "No changes. Your infrastructure matches the configuration."
#    CodeBuild가 S3 state를 갱신했기 때문에 로컬과 동일
#    drift가 뜨면 state 동기화가 안 된 것
```

### Step 6 — 실제 변경 배포

```bash
# 03_real/main.tf에서 태그 하나 수정 — 예: default_tags에 Env = "cicd" 추가
git commit -am "add env tag" && git push origin main
```

- 파이프라인이 **자동으로 다시 시작** → Plan 로그에 실제 diff (`+ Env = "cicd"`)
- 로그를 읽고 승인 → apply 완료 → AWS 콘솔에서 리소스 태그 확인

### Step 7 — 실패 시나리오 (의도적 오류 — 중요)

```bash
# 03_real에 문법 오류를 넣고 push (예: 중괄호 하나 삭제)
git commit -am "broken" && git push origin main
```

- Plan 단계가 **빨갛게 실패** → 파이프라인 중단 → 인프라 변화 0
- CodeBuild 로그에서 에러 확인 → 고쳐서 다시 push → 정상 통과 확인

**이게 승인 게이트의 의미**: 로컬 apply였다면 plan을 안 보고 바로 고쳤을 실수가 파이프라인에서 걸러집니다.
"잘못된 코드가 apply까지 도달하지 않는다"가 CI/CD의 핵심 가치입니다.

### Step 8 — 다음 단계 / 정리

- 앱 배포는 `11_gitops_app`으로 — 같은 리포의 `dev` 브랜치를 감시하는 별도 파이프라인
- 정리는 역순:

```bash
cd 11_gitops_app && terraform destroy        # 사용했다면 먼저
cd 10_gitops_infra && terraform destroy      # tfstate 버킷은 prevent_destroy로 보호됨
```

`prevent_destroy` 때문에 버킷 삭제가 막히면 → 수동으로 버킷 비우기 + 라이프사이클 주석 처리 후 재destroy.
remote_state로 10을 참조하는 단계가 남아있으면 10을 지울 수 없습니다.

---

## 테스트 요약 — "CI/CD가 동작한다"는 뭘 확인하는가

| # | 테스트 | 절차 | 성공 기준 |
| --- | --- | --- | --- |
| ① | 트리거 | `git push origin main` | 수동 개입 없이 실행 ID 생성 |
| ② | 단계 순서 | Source→Plan→Approve→Apply 관찰 | Plan 로그에 실제 diff |
| ③ | 승인 게이트 | 승인 안 누르고 대기 | Apply 미실행 = 무승인 무배포 증명 |
| ④ | 실패 차단 | 문법 오류 push | Plan 빨간색 + 파이프라인 중단 + 인프라 무결 |
| ⑤ | 상태 정합 | `cd 03_real && terraform plan` | `No changes` |

## 소스 구조

```text
10_gitops_infra/           # 저장소 계층 + 인프라 파이프라인 (main 소스)
11_gitops_app/             # 앱 파이프라인 — dev 브랜치 소스
```

## 파일·디렉터리 역할

| 경로 | 역할 |
| --- | --- |
| `10_gitops_infra/02-state.tf` | 공용 저장소 — tfstate·lock·artifact 버킷 |
| `10_gitops_infra/main.tf` | 인프라 파이프라인 + 공용 CodeBuild/Pipeline 역할 |
| `10_gitops_infra/03-outputs.tf` | 11이 읽는 출력 — 버킷·역할·connection arn |
| `buildspec-plan.yml` / `buildspec-apply.yml` | CodeBuild 실행 명령 — phases/artifacts |
| `11_gitops_app/` | 앱 파이프라인 — dev 브랜치 소스, 10의 출력을 remote_state로 참조 |

## 단계 간 연결

- `03_real`이 배포 대상 — pipeline이 그 .tf 코드를 plan/apply (`TF_DIR` 변수로 지정)
- 03_real의 state가 이 디렉터리가 만든 S3 bucket + DynamoDB로 이동 (`-migrate-state`)
- remote_state는 `11_gitops_app`에서 사용 — 수명주기가 다른 계층을 분리할 때 의미가 있음

## 주의사항

- connection 승인(PENDING→AVAILABLE)을 안 하면 파이프라인이 Source에서 멈춥니다 — OAuth는 수동 1회
- CodeBuild는 빌드 시간만큼 과금 (소액), 수동 승인 대기는 무료
- `tfstate` 버킷은 `prevent_destroy` — 삭제하려면 수동으로 라이프사이클 해제
- CodeBuild 역할에 AdministratorAccess — **학습용 한정**, 실무는 최소권한으로 교체
- 브랜치 필터만 있고 경로 필터는 없음 — main에 readme만 바꿔도 파이프라인이 돕니다

## 산출물

- git push 한 번으로 plan→승인→apply가 돌아가는 파이프라인
- 원격 state(S3+DynamoDB) 구조 이해

## 완료 기준

- [ ] 파이프라인 4단계(Source·Plan·Approve·Apply)의 역할을 설명할 수 있다
- [ ] 로컬 state와 S3 backend의 차이를 안다
- [ ] buildspec의 install/build/artifacts를 읽을 수 있다
- [ ] connection PENDING→AVAILABLE 승인이 왜 수동인지 설명할 수 있다
- [ ] Step 0~8을 안 보고 재현할 수 있다
