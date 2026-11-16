# 12_app_pipeline — 애플리케이션 배포 파이프라인 (dev 브랜치)

앱 코드 push → docker build → ECR push → EKS 배포까지의 앱 파이프라인입니다.
11_infra_pipeline과 **같은 GitHub 리포**를 쓰되 브랜치로 분리합니다 — `main`이 운영(인프라) 트리거라면
`dev`가 개발(앱) 트리거입니다. "리포는 하나, 환경은 브랜치로"라는 GitOps 패턴입니다.

## 리포 구조 — 리포 1개, 브랜치 2개

```text
yundo-main/aws-terraform  (GitHub 리포 하나)
├── main 브랜치  → 11_infra_pipeline 트리거 (운영)
└── dev  브랜치  → 12_app_pipeline 앱 파이프라인 트리거 (개발)
```

CodeCommit·별도 리포 없이 평소 하던 `git push`만으로 두 파이프라인이 각자의 브랜치를 감시합니다.

## 전제 조건

1. **10_backend·11_infra_pipeline이 apply된 상태** — connection·공용 역할·artifact 버킷을 remote_state로 참조
   (11_infra_pipeline을 GitHub 버전으로 apply해야 `github_connection_arn` 출력이 생깁니다)
2. **GitHub connection AVAILABLE** — 11_infra_pipeline에서 이미 승인했다면 재사용
3. **EKS 클러스터** — `03_real` apply (EKS 포함) 또는 `eks_cluster_name` 변수 변경
4. **aws-auth 등록** — CodeBuild 역할이 kubectl을 쓰려면 EKS의 aws-auth ConfigMap에 역할 추가:
   ```bash
   kubectl edit configmap aws-auth -n kube-system
   # mapRoles에 추가:
   #   - rolearn: <11_infra_pipeline outputs의 codebuild_role_arn>
   #     username: codebuild
   #     groups: ["system:masters"]
   ```

## 만드는 리소스 (5개)

| 리소스 | 역할 |
| --- | --- |
| `aws_ecr_repository.app` | 앱 이미지 저장소 |
| `aws_codebuild_project.app_build` | `privileged_mode` docker build → ECR push |
| `aws_codebuild_project.app_deploy` | kubectl apply + set image + rollout 대기 |
| `aws_codepipeline.app` | Source→Build→Deploy 3단계 — 소스는 11_infra_pipeline의 connection 공용 |
| (11_infra_pipeline의 `aws_codestarconnections_connection` 재사용) | 별도 연결 생성 없음 — 역할 권한도 이미 커버 |

## 실행

```bash
terraform init
terraform apply
```

## 사용 흐름 — dev 브랜치 push

```bash
# 1) dev 브랜치 생성 (한 번) — 앱 파이프라인은 dev를 감시
git push origin main:dev

# 2) 앱 코드를 고치고 push → 이미지 빌드 → EKS 배포 자동 실행
#    (12_app_pipeline/app/ 안 파일을 수정 → 커밋 → dev로 push)
git commit -am "app v2"
git push origin main:dev    # main의 변경을 dev로 넘기며 트리거
```

- Build 로그에서 `build tag: <커밋 해시>` 확인 → Deploy 로그에서 `set image`·rollout 대기
- `kubectl rollout status deploy/sample-app` + `kubectl port-forward svc/sample-app 8080:80`

**왜 브랜치로 나누는가**: `main`에 push할 때마다 앱 이미지까지 재빌드되면 낭비입니다.
브랜치가 트리거 경계라, 인프라 변경은 `main`, 앱 변경은 `dev`로 흐름을 나눕니다 —
단일 리포의 단순함과 리포 분리의 격리 효과를 동시에 얻는 절충입니다.

## 핵심 포인트

- `local.*`은 10_backend·11_infra_pipeline의 출력입니다 — connection·역할·버킷을 새로 안 만듭니다.
- `imageDetail.json`이 빌드→배포 간 이미지 URI를 전달하는 artifact입니다.
- buildspec은 리포 안 경로(`12_app_pipeline/`)로 참조 — 소스가 모노리포라 디렉터리 그대로 동작합니다.
- 리포 분리(실제 다른 리포)를 원하면 10과 같은 connection으로 `github_repo`만 바꾸면 됩니다 — 구조는 같습니다.
