# 10_backend — 저장소 계층

CI/CD 전체의 기반이 되는 **저장소 리소스**만 만드는 단계입니다. 어떤 파이프라인도 아직 없습니다.

## 만드는 리소스 (6개)

| 리소스 | 역할 |
| --- | --- |
| `aws_s3_bucket.tfstate` + 버저닝·암호화·public차단 | Terraform state를 원격 저장 — `prevent_destroy`로 보호 |
| `aws_dynamodb_table.tf_lock` | state 동시 수정 방지 잠금 |
| `aws_s3_bucket.artifacts` + public차단 | 파이프라인 단계 간 산출물(코드·tfplan) 전달 통로 |

## 실행

```bash
terraform init
terraform apply
terraform output    # 11_infra_pipeline·12_app_pipeline이 remote_state로 읽는 값 확인
```

## 확인

```bash
aws s3 ls | grep aws-tf-cicd            # 버킷 2개
aws dynamodb list-tables                # lock 테이블
```

## 핵심 포인트

- 이 단계의 `terraform.tfstate`는 **로컬**에 있습니다 — 이 단계 자체는 로컬 state.
  파이프라인이 쓸 S3 backend는 이 단계가 "만드는 리소스"입니다.
- `outputs.tf`의 값을 11_infra_pipeline·12_app_pipeline이 `terraform_remote_state`로 읽습니다.
- tfstate 버킷은 `prevent_destroy` — 이후 단계 전부 지워도 여기는 보호됩니다.
