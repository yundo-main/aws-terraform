# step2_infra_pipeline — 인프라 GitOps 파이프라인

`.tf` 코드 push → 자동 plan → 수동 승인 → apply가 돌아가는 파이프라인입니다.
artifact 버킷은 step1의 출력을 `00-remote-state.tf`로 읽어옵니다.

## 만드는 리소스 (9개)

| 리소스 | 역할 |
| --- | --- |
| `aws_codecommit_repository.src` | 인프라 코드용 git 리포 — push = 트리거 |
| `aws_iam_role.codebuild` + admin | 빌드 실행 역할 (step3도 공용) |
| `aws_codebuild_project.plan/apply` | terraform plan / apply 실행기 |
| `aws_iam_role.pipeline` + 정책 | 파이프라인 실행 역할 (step3도 공용) |
| `aws_codepipeline.tf` | Source→Plan→Approve→Apply 4단계 |

## 실행

```bash
terraform init
terraform apply          # step1 state가 먼저 있어야 함
terraform output backend_snippet   # 03_real backend 설정
```

## 사용 흐름

```bash
# 1) 03_real을 S3 backend로 전환
cd ../../03_real && terraform init -migrate-state

# 2) 인프라 리모트 등록 + push → 파이프라인 자동 실행
git remote add cicd <repo_clone_http 출력값>
git push cicd main
```

- CodePipeline 콘솔에서 Source→Plan→Approve→Apply 확인
- Approve에서 멈추는 게 정상 — Plan 로그를 보고 승인

## 핵심 포인트

- `local.artifacts_bucket` 같은 `local.*` 값이 remote_state에서 온 것입니다.
- 공용 IAM 역할 2개는 이 단계 소유 — `outputs.tf`로 step3에 전달됩니다.
- `buildspec-*.yml`은 이 디렉터리 안에 있어야 리포 경로와 일치합니다.
