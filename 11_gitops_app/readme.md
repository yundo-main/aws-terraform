# 11_gitops_app — 애플리케이션 배포 파이프라인 (dev 브랜치)

앱 코드 push → docker build → ECR push → EKS 배포까지의 앱 파이프라인입니다.
10_gitops_infra와 **같은 GitHub 리포**를 쓰되 브랜치로 분리합니다 — `main`이 운영(인프라) 트리거라면
`dev`가 개발(앱) 트리거입니다. "리포는 하나, 환경은 브랜치로"라는 GitOps 패턴입니다.

## 리포 구조 — 리포 1개, 브랜치 2개

```text
yundo-main/aws-terraform  (GitHub 리포 하나)
├── main 브랜치  → 10_gitops_infra 인프라 파이프라인 트리거 (운영)
└── dev  브랜치  → 11_gitops_app 앱 파이프라인 트리거 (개발)
```

CodeCommit·별도 리포 없이 평소 하던 `git push`만으로 두 파이프라인이 각자의 브랜치를 감시합니다.

## 만드는 리소스 (5개)

| 리소스 | 역할 |
| --- | --- |
| `aws_ecr_repository.app` | 앱 이미지 저장소 |
| `aws_codebuild_project.app_build` | `privileged_mode` docker build → ECR push |
| `aws_codebuild_project.app_deploy` | kubectl apply + set image + rollout 대기 |
| `aws_codepipeline.app` | Source→Build→Deploy 3단계 — 소스는 10의 connection 공용 |
| (10의 connection·IAM 역할 재사용) | 별도 연결 생성 없음 — remote_state로 참조 |

## 핵심 포인트

- `local.*`은 10_gitops_infra의 출력입니다 — connection·역할·버킷을 새로 안 만듭니다.
- `imageDetail.json`이 빌드→배포 간 이미지 URI를 전달하는 artifact입니다.
- buildspec은 리포 안 경로(`11_gitops_app/buildspec-app-*.yml`)로 참조 — 소스가 모노리포라 그대로 동작합니다.
- 이미지 태그 = 커밋 해시 앞 8자리 — "어느 커밋이 배포됐는가"가 태그에 박힙니다.

---

## 실습 절차 — Step 0부터 Step 8까지

**장면**: dev 브랜치에 push하면 샘플 앱이 자동으로 빌드·배포되는 파이프라인을 만듭니다.
모든 git 명령은 **리포 루트**에서 실행합니다.

### Step 0 — 전제 확인 (4가지 모두 충족해야 진행)

```bash
# 리포 루트에서
cd 10_gitops_infra && terraform output codebuild_role_arn     # ① 10이 apply된 상태
aws codeconnections list-connections \
  --query 'Connections[*].[ConnectionName,ConnectionStatus]' --output table
# ② <project>-github  AVAILABLE
aws eks list-clusters --region ap-northeast-2                 # ③ EKS 클러스터 존재
kubectl get nodes                                             # ④ kubectl이 클러스터에 닿음
```

- ① 없으면 → `cd 10_gitops_infra && terraform apply` 먼저
- ③ 없으면 → `cd 03_real && terraform apply`로 EKS 생성, 또는 `eks_cluster_name` 변수를 살아있는 클러스터로

### Step 1 — 앱 파이프라인 생성

```bash
cd 11_gitops_app
terraform init        # remote_state로 ../10_gitops_infra를 읽음
terraform apply       # → 5 to add (ECR + CodeBuild×2 + Pipeline + ECR policy)
```

**확인**: `terraform output` — ECR 리포 URL·파이프라인 이름.
**자주 나는 오류**: `Error reading remote state` → 10이 apply 안 됐거나 `terraform.tfstate`가 없음.

### Step 2 — aws-auth 등록 (수동 1회, 필수)

CodeBuild 역할이 kubectl을 쓰려면 EKS의 aws-auth ConfigMap에 등록돼야 합니다 — 안 하면 Deploy 단계에서
`Unauthorized`로 실패합니다.

```bash
ROLE_ARN=$(cd 10_gitops_infra && terraform output -raw codebuild_role_arn)
echo $ROLE_ARN   # 예: arn:aws:iam::<acct>:role/<project>-codebuild

kubectl edit configmap aws-auth -n kube-system
# mapRoles: 아래에 추가
#   - rolearn: <위의 $ROLE_ARN>
#     username: codebuild
#     groups: ["system:masters"]
```

**확인**: `kubectl get configmap aws-auth -n kube-system -o yaml | grep codebuild` → rolearn이 보여야 함.

### Step 3 — dev 브랜치 생성 (최초 1회)

```bash
git push origin main:dev    # 현재 main 내용으로 dev 브랜치 생성
```

이 한 번으로 GitHub에 dev가 생기고, 앱 파이프라인이 dev 브랜치 감시를 시작합니다.

### Step 4 — 첫 배포 관찰

```bash
# 앱 코드에 작은 변경 — 예: index.html 한 줄 수정
cd 11_gitops_app/app
echo "<!-- v1 -->" >> index.html
git commit -am "app v1" && git push origin main:dev
```

**관찰** — CodePipeline 콘솔 → 앱 파이프라인의 3단계 로그:

| 단계 | 로그에서 보이는 것 | 의미 |
| --- | --- | --- |
| Source | dev 브랜치 소스 다운로드 | webhook 트리거 동작 |
| Build | `docker build` → `build tag: <커밋8>` → ECR push | 이미지 생성·태그 부여 |
| Deploy | `deploy image: <uri>` → `set image` → `rollout status` | EKS에 새 버전 적용 |

승인 게이트는 없습니다 — 개발 파이프라인은 push 후 자동으로 끝까지 갑니다 (운영과의 비대칭이 표준).

### Step 5 — 배포 검증

```bash
# 이미지가 ECR에 올라갔는지
aws ecr describe-images --repository-name <ecr-repo명> \
  --query 'imageDetails[*].imageTags' --output table

# EKS에 rollout됐는지
kubectl rollout status deployment/sample-app
kubectl get pods -l app=sample-app
kubectl describe deploy sample-app | grep Image:    # 태그 = 커밋 8자리인가

# 실제 동작 확인
kubectl port-forward svc/sample-app 8080:80 &
curl localhost:8080     # index.html 내용이 보이면 끝
```

`Image:`에 커밋 해시 태그가 보이면 **"내 push가 배포됐다"**의 증명이 완성됩니다.

### Step 6 — 변경 배포 (두 번째 사이클)

```bash
# index.html의 본문을 바꾸고 다시 dev로 push
git commit -am "app v2" && git push origin main:dev
```

- Build 로그에서 **새 태그**(새 커밋 8자리) 확인
- `kubectl get pods -w` — 옛 pod가 Terminating → 새 pod가 Running으로 바뀌는 롤링 확인
- `curl localhost:8080`으로 바뀐 내용 확인

### Step 7 — 롤백 체험

```bash
kubectl rollout undo deployment/sample-app      # 이전 리비전으로 즉시 복귀
kubectl rollout status deployment/sample-app
kubectl describe deploy sample-app | grep Image:   # 태그가 이전 커밋으로 되돌아감
```

배포 파이프라인이 있어도 수동 롤백은 언제나 가능합니다 — `rollout undo`가 비상구입니다.
(파이프라인식 복구는 "되돌린 코드를 다시 dev에 push" = revert commit)

### Step 8 — 정리

```bash
cd 11_gitops_app && terraform destroy    # ECR·빌드·파이프라인 삭제 (5개)
# 이후 10을 지울 땐 10_gitops_infra readme의 Step 8 참조
```

remote_state로 10을 참조하므로 **11 → 10 순서가 정리 순서**입니다 — 거꾸로 지우면 참조가 깨집니다.

---

## 테스트 요약

| # | 테스트 | 절차 | 성공 기준 |
| --- | --- | --- | --- |
| ① | dev 트리거 | `git push origin main:dev` | 앱 파이프라인만 시작 (인프라 파이프라인은 안 돔) |
| ② | 브랜치 격리 | main에만 push | 앱 파이프라인 미동작 — 브랜치가 경계임을 증명 |
| ③ | 빌드 | Build 로그 확인 | `build tag: <커밋8>` + ECR에 태그 존재 |
| ④ | 배포 | `describe deploy`의 Image | 이미지 태그 = 방금 커밋 해시 |
| ⑤ | 롤아웃 | `get pods -w` | 옛 pod 종료 → 새 pod 기동, 다운타임 없음 |

## 파일·디렉터리 역할

| 경로 | 역할 |
| --- | --- |
| `00-remote-state.tf` | `../10_gitops_infra/terraform.tfstate`를 읽는 data 소스 |
| `main.tf` | ECR + CodeBuild×2 + Pipeline 정의 |
| `buildspec-app-build.yml` | docker build → ECR push → imageDetail.json 생성 |
| `buildspec-app-deploy.yml` | imageDetail 읽기 → kubectl apply/set image → rollout 대기 |
| `app/` | 샘플 앱 — `Dockerfile`·`deployment.yaml`·`index.html` |

## 왜 브랜치로 나누는가

`main`에 push할 때마다 앱 이미지까지 재빌드되면 낭비입니다.
브랜치가 트리거 경계라, 인프라 변경은 `main`, 앱 변경은 `dev`로 흐름을 나눕니다 —
단일 리포의 단순함과 리포 분리의 격리 효과를 동시에 얻는 절충입니다.
리포 분리(실제 다른 리포)를 원하면 같은 connection으로 `github_repo`만 바꾸면 됩니다 — 구조는 같습니다.

## 주의사항

- Deploy의 kubectl은 **EKS 퍼블릭 엔드포인트**로 접근 — 프라이빗 전용이면 별도 대책 필요
- aws-auth 미등록이 Deploy 실패의 가장 흔한 원인 — `Unauthorized` 로그가 보이면 Step 2로
- `system:masters` 권한은 학습용 — 실무는 네임스페이스 범위 Role로 제한
- dev 브랜치가 없으면 파이프라인이 Source에서 실패 — Step 3 필수

## 산출물

- dev 브랜치 push 한 번으로 docker build → ECR → EKS까지 자동 배포
- "리포 하나·브랜치 둘" GitOps 패턴의 실전 경험

## 완료 기준

- [ ] `git push origin main:dev`가 앱 파이프라인만 트리거함을 확인했다
- [ ] imageDetail.json이 빌드→배포 계약임을 설명할 수 있다
- [ ] aws-auth가 왜 필요한지 (IAM ≠ 클러스터 권한) 설명할 수 있다
- [ ] 커밋 해시 태그로 "어느 코드가 배포됐는가"를 추적할 수 있다
- [ ] `kubectl rollout undo`로 롤백할 수 있다
