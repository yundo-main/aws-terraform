# step3_app_pipeline — 애플리케이션 배포 파이프라인

앱 코드 push → docker build → ECR push → EKS 배포까지의 앱 파이프라인입니다.
step1의 artifact 버킷과 step2의 공용 역할을 remote_state로 참조합니다.

## 전제 조건

1. **step1·step2가 apply된 상태** — remote_state가 읽을 state 파일 필요
2. **EKS 클러스터** — `03_real` apply (EKS 포함) 또는 `eks_cluster_name` 변수 변경
3. **aws-auth 등록** — CodeBuild 역할이 kubectl을 쓰려면 EKS의 aws-auth ConfigMap에 역할 추가:
   ```bash
   kubectl edit configmap aws-auth -n kube-system
   # mapRoles에 추가:
   #   - rolearn: <step2 outputs의 codebuild_role_arn>
   #     username: codebuild
   #     groups: ["system:masters"]
   ```

## 만드는 리소스 (5개)

| 리소스 | 역할 |
| --- | --- |
| `aws_ecr_repository.app` | 앱 이미지 저장소 |
| `aws_codecommit_repository.app` | 앱 소스 리포 |
| `aws_codebuild_project.app_build` | `privileged_mode` docker build → ECR push |
| `aws_codebuild_project.app_deploy` | kubectl apply + set image + rollout 대기 |
| `aws_codepipeline.app` | Source→Build→Deploy 3단계 |

## 실행

```bash
terraform init
terraform apply
terraform output app_repo_clone_http   # 앱 리포 URL
```

## 사용 흐름

```bash
git remote add app <app_repo_clone_http>
git push app main    # → 이미지 빌드 → EKS 배포 자동 실행
kubectl get pods -l app=sample-app     # 배포 확인
```

## 핵심 포인트

- `local.codebuild_role_arn`·`local.pipeline_role_arn`은 step2의 출력입니다 — 역할을 새로 안 만들고 공용으로 씁니다.
- `imageDetail.json`이 빌드→배포 간 이미지 URI를 전달하는 artifact입니다.
- `10_cicd/app/`의 Dockerfile·deployment.yaml이 배포 대상 샘플입니다.
