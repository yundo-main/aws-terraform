# 10_cicd — AWS 네이티브 CI/CD 파이프라인

03_real의 표준 레이아웃으로 Terraform GitOps 파이프라인을 구성하는 단계입니다.
Git push → 자동 plan → 수동 승인 → apply까지 **전부 AWS 서비스**로만 동작합니다.

## 학습 목표

- AWS 네이티브 CI/CD 서비스(CodeCommit·CodeBuild·CodePipeline)의 역할을 안다
- Terraform을 CI/CD에 올릴 때 필요한 S3 backend·DynamoDB lock을 설명할 수 있다
- buildspec.yml의 phases 구조를 읽을 수 있다
- plan→승인→apply 게이트가 왜 필요한지 설명할 수 있다

## 핵심 내용

- S3 backend + DynamoDB — CI 환경에서 필수인 원격 state·잠금
- CodeCommit — git 소스 저장소 (push = 파이프라인 트리거)
- CodeBuild — terraform 설치 → init → validate → plan → apply 실행
- CodePipeline — 단계 오케스트레이션 + artifact 전달 + 수동 승인 게이트
- EventBridge — push 감지 규칙 (PollForSourceChanges=false면 자동 생성)

## 이 파이프라인의 범위

이 단계가 만드는 것은 **인프라 파이프라인**입니다 — `.tf` 코드 변경을 자동 배포합니다.
애플리케이션 배포는 별도 파이프라인입니다:

```text
[인프라 파이프라인]  ← 이 디렉터리가 만드는 것
.tf push → plan → 승인 → apply   (VPC·EKS·RDS 같은 뼈대)

[앱 파이프라인]      ← 별도로 필요한 것 (확장 과제)
앱 코드 push → docker build → ECR push → EKS/EC2 배포
```

| 앱 파이프라인 구성 요소 | AWS 서비스 |
| --- | --- |
| 이미지 빌드 → ECR push | CodeBuild + ECR |
| EKS 배포 | CodeBuild에서 `kubectl apply` (또는 helm) |
| EC2 배포 | CodeDeploy (blue/green) |
| 실패 복귀 | `kubectl rollout undo` / CodeDeploy 자동 롤백 |
| 결과 알림 | SNS / EventBridge |

## 앱 배포 파이프라인 (app-pipeline.tf)

앱 소스 push → 이미지 빌드 → EKS 배포까지 구성된 두 번째 파이프라인:

```text
앱 리포 push → [Build] CodeBuild(docker build → ECR push)
            → [Deploy] CodeBuild(kubectl apply + set image)
```

| 리소스 | 역할 |
| --- | --- |
| `aws_ecr_repository.app` | 앱 이미지 저장소 |
| `aws_codecommit_repository.app` | 앱 소스 리포 (`app/` 디렉터리 샘플 포함) |
| `app_build` 프로젝트 | `privileged_mode`로 docker build → 태그=커밋 해시 8자리 |
| `app_deploy` 프로젝트 | `kubectl apply` + `set image` + rollout status 대기 |
| `imageDetail.json` | 빌드→배포 간 이미지 URI 전달 artifact |

**전제 조건**

1. EKS 클러스터가 있어야 합니다 — `03_real` apply (EKS 포함) 또는 `eks_cluster_name` 변수 변경
2. **aws-auth 등록** — CodeBuild 역할이 `kubectl`을 쓰려면 EKS의 aws-auth ConfigMap에 역할을 추가해야 합니다:
   ```bash
   kubectl edit configmap aws-auth -n kube-system
   # mapRoles에 추가:
   #   - rolearn: <app_deploy가 쓰는 codebuild 역할 ARN>
   #     username: codebuild
   #     groups: ["system:masters"]
   ```

## 이론적 배경

로컬 `terraform apply`는 개발자 PC에서 state를 만지지만, 팀·자동화 환경에서는 state를 **S3 backend**에 두고 DynamoDB로 잠급니다. 파이프라인의 CodeBuild는 이 S3 state를 읽어 plan→apply합니다. plan과 apply 사이에 수동 승인을 둬서 "계획 확인 없이 인프라가 바뀌는" 사고를 막습니다.

## 실습 시나리오

**장면**: 수동 `terraform apply`로 관리하던 03_real 인프라를 GitOps로 전환 — push만으로 배포되는 구조를 직접 경험합니다.

### 준비 — 파이프라인 인프라 생성

```bash
cd step1_backend && terraform init && terraform apply
cd ../step2_infra_pipeline && terraform init && terraform apply
terraform output backend_snippet    # 03_real용 backend 설정 복사
```

### 장면 1 — 로컬 state → S3 backend 전환

1. `03_real/versions.tf`의 `terraform {}` 블록에 backend_snippet 붙여넣기
2. `cd ../../03_real && terraform init -migrate-state` → `yes`
3. `terraform state list` — S3에서 읽히는지 확인, S3 콘솔에서 state 파일 확인

> 학습 포인트: 이 순간부터 state는 내 PC가 아니라 S3가 진실이 됩니다.

### 장면 2 — 첫 파이프라인 실행

```bash
git remote add cicd <step2의 repo_clone_http>
git push cicd main
```

- CodePipeline 콘솔에서 Source → Plan 단계가 초록→파랑으로 진행
- Plan 완료 후 **Approve에서 파이프라인이 멈춥니다** — 승인 없이는 인프라가 안 바뀜

### 장면 3 — 승인 게이트 경험

1. Plan 단계 로그(CodeBuild)에서 `Plan: 0 to add` 확인
2. Approve의 승인 버튼 클릭 → Apply 실행 → 완료

### 장면 4 — 실제 변경 배포

1. `03_real/main.tf`에서 태그 하나 수정 (예: default_tags에 `Env = "cicd"` 추가)
2. `git commit -am "add env tag" && git push cicd main`
3. 파이프라인이 **자동으로 다시 시작** → Plan 로그에 실제 diff 표시
4. 로그를 읽고 승인 → apply 완료 → AWS에서 태그 확인

### 장면 5 — 실패 경험 (의도적 오류)

1. `03_real`에 문법 오류를 넣고 push (예: 중괄호 하나 삭제)
2. Plan 단계가 **빨갛게 실패** — 파이프라인이 잘못된 코드를 차단
3. 로그에서 에러 확인 → 고쳐서 push → 정상 통과 확인

> 이게 승인 게이트의 의미: 로컬 apply였다면 plan을 안 보고 바로 고쳤을 실수가 파이프라인에서 걸러집니다.

### 선택 — 앱 파이프라인 (EKS 필요)

step3 apply + aws-auth 등록 후, 앱 리포에 샘플 push → 이미지 빌드→EKS 배포 확인.

### 파이프라인 테스트 — "CI/CD가 동작한다"는 뭘 확인하는가

apply가 된 것과 파이프라인이 동작하는 것은 다른 문제입니다. 아래 항목을 순서대로 검증합니다.

**테스트 ① 트리거 — push가 파이프라인을 시작시키는가**

```bash
echo "# test" >> ../../03_real/main.tf && git commit -am "ci test" && git push cicd main
```

- **확인**: CodePipeline 콘솔에서 새 실행이 시작됨 — CodeBuild를 수동 실행하지 않았는데 시작됐다면 EventBridge 감지 성공
- **실패 시**: 리모트 URL 오타 → `terraform output repo_clone_http`로 교정 / CodeCommit 미지원 계정이면 리포 생성 단계에서 이미 실패했어야 함

**테스트 ② 각 단계가 순서대로 성공하는가**

| 단계 | 확인할 것 | 성공 기준 |
| --- | --- | --- |
| Source | SourceArtifact가 artifact 버킷에 저장됨 | 단계 초록 |
| Plan | CodeBuild 로그에 `terraform plan` 출력 | "Plan: N to add" 로그 |
| Approve | 실행이 멈춤 | 콘솔에 승인 버튼 대기 — **파이프라인이 알아서 안 넘어감** |
| Apply | `terraform apply tfplan` 로그 | plan 결과와 동일하게 적용 |

**테스트 ③ 승인 게이트가 실제로 막는가**

- Plan까지 성공 후 **승인을 안 누름** → Apply가 실행되지 않는 걸 확인 (게이트 동작 증명)
- 승인 누르기 전 Plan 로그의 변경 내용 읽기 — 승인 = "이 plan을 승인"임을 체감

**테스트 ④ 거부 — 잘못된 코드를 차단하는가**

```bash
# 일부러 문법 오류 넣고 push
sed -i '' 's/cidr_block = /cidr_block == /' ../../03_real/main.tf
git commit -am "broken" && git push cicd main
# → Plan 단계 빨간색 → 파이프라인 멈춤 → 되돌리고 재push
```

- **이게 CI/CD의 핵심 가치**: 로컬이었다면 에러가 "내 터미널"에서 끝나지만, 파이프라인에서는 "배포가 차단"됩니다.

**테스트 ⑤ 상태 정합 — 파이프라인 apply 후 state가 갱신됐는가**

```bash
cd ../../03_real && terraform plan   # 로컬에서 확인
# → "No changes"가 나와야 함 — CodeBuild가 S3 state를 갱신했기 때문
# drift가 뜨면 state가 제대로 동기화 안 된 것
```

**테스트 ⑥ 앱 파이프라인 (step3 — 선택)**

```bash
# app/index.html 수정 → push → Build(docker)·Deploy(kubectl) 로그 확인
kubectl get pods -l app=sample-app -w   # 새 pod 롤링 확인
kubectl rollout status deployment/sample-app
```

- 이미지 태그 = 커밋 해시 앞 8자리 — `kubectl describe deploy`로 태그가 새 값인지 확인하면 "내 push가 배포됐다"가 증명됩니다.

### 정리

```bash
cd step3_app_pipeline && terraform destroy   # 사용했다면
cd ../step2_infra_pipeline && terraform destroy
cd ../step1_backend && terraform destroy     # tfstate 버킷은 prevent_destroy로 보호됨
```

## 소스 구조

```text
10_cicd/
├── readme.md
├── slides/                        # 파이프라인 구조 슬라이드 12장
├── app/                           # 샘플 앱 — step3이 배포하는 대상
├── step1_backend/                 # 저장소 계층 + readme.md (단계별 실습)
│   ├── 02-state.tf                # tfstate 버킷·lock 테이블·artifact 버킷
│   └── outputs.tf                 # step2·3가 읽는 값
├── step2_infra_pipeline/          # 인프라 파이프라인 + readme.md
│   ├── 00-remote-state.tf         # → step1 참조
│   ├── main.tf                    # CodeCommit·CodeBuild×2·Pipeline·공용 IAM
│   ├── buildspec-plan.yml         # init → validate → plan -out
│   ├── buildspec-apply.yml        # apply tfplan
│   └── outputs.tf                 # 공용 역할 ARN → step3가 참조
└── step3_app_pipeline/            # 앱 파이프라인 + readme.md
    ├── 00-remote-state.tf         # → step1·step2 참조
    ├── main.tf                    # ECR·앱 리포·빌드/배포·파이프라인
    ├── buildspec-app-build.yml    # docker build → ECR push
    └── buildspec-app-deploy.yml   # kubectl apply + set image
```

## 파일·디렉터리 역할

| 경로 | 역할 |
| --- | --- |
| `step1_backend/` | 공용 저장소 — tfstate·lock·artifact 버킷 |
| `step2_infra_pipeline/` | 인프라 파이프라인 + 공용 CodeBuild/Pipeline 역할 |
| `step3_app_pipeline/` | 앱 파이프라인 — step1·2의 출력을 remote_state로 참조 |
| `buildspec-*.yml` | CodeBuild 실행 명령 — phases/artifacts |

## 단계 간 연결

- `03_real`이 배포 대상 — pipeline이 그 .tf 코드를 plan/apply
- state는 10_cicd가 만든 S3 bucket + DynamoDB로 이동 (`-migrate-state`)
- remote_state는 `04_https`와 여기서 사용 — 수명주기가 다른 계층을 분리할 때 의미가 있음

## 주의사항

- CodeCommit은 신규 AWS 고객에게 제공이 제한될 수 있습니다 — 생성 실패 시 S3 소스 방식으로 대체
- CodeBuild는 빌드 시간만큼 과금 (소액), 수동 승인 대기는 무료
- `tfstate` 버킷은 `prevent_destroy` — 삭제하려면 수동으로 라이프사이클 해제
- CodeBuild 역할에 AdministratorAccess — **학습용 한정**, 실무는 최소권한으로 교체

## 산출물

- git push 한 번으로 plan→승인→apply가 돌아가는 파이프라인
- 원격 state(S3+DynamoDB) 구조 이해

## 완료 기준

- [ ] 파이프라인 4단계(Source·Plan·Approve·Apply)의 역할을 설명할 수 있다
- [ ] 로컬 state와 S3 backend의 차이를 안다
- [ ] buildspec의 install/build/artifacts를 읽을 수 있다
