# 04_https — ACM 인증서 + HTTPS 리스너 (선택 단계)

03_real 위에 HTTPS만 얹는 분리 단계입니다. 03이 만든 ALB·Route53 존을 `terraform_remote_state`로 읽어, 인증서 발급·443 규칙·HTTPS 리스너만 추가합니다. 02·03은 하드코딩→변수화·단일 state를 배웠다면, 여기서는 **별도 state에서 다른 state의 리소스를 확장하는 방법**을 배웁니다.

## 학습 목표

- `terraform_remote_state`로 다른 단계의 outputs를 읽어 참조한다
- 기존 리소스를 수정하지 않고 규칙·리스너를 "부착"해 확장한다
- ACM DNS 검증이 Route53과 함께 완전 자동화되는 흐름을 이해한다

## 핵심 내용

- remote_state: `backend = "local"` + `path = "../03_real/terraform.tfstate"`
- `local.real`로 outputs를 짧게 참조 — `local.real.alb_arn` 등
- `domain_enabled`가 거짓이면 이 단계 리소스 전체가 count=0 (빈 plan)
- 03의 SG·ALB를 건드리지 않고 `aws_security_group_rule`·`aws_lb_listener`로 확장

## 이론적 배경

같은 state에 없는 리소스는 `aws_lb.app.arn`처럼 직접 참조할 수 없습니다. Terraform은 자기 state에 기록된 것만 알기 때문에, 다른 단계가 만든 리소스의 ID는 ① remote_state로 읽거나 ② 변수로 직접 전달하거나 ③ data 소스로 태그 검색해야 합니다. 이 단계는 ①을 실습합니다 — 02에서 배운 "파일을 나누면 ID 전달이 필요하다"의 실제 사례입니다.

인증서는 DNS 검증을 씁니다 — ACM이 요구하는 CNAME 레코드를 Route53 존에 자동 생성하면 소유권이 증명되어 콘솔 클릭 없이 발급이 끝납니다.

## 실습

**전제**: 03_real이 apply 완료되어 `terraform.tfstate`에 outputs가 있어야 합니다. 없으면 plan 단계에서 remote_state 읽기 오류가 납니다.

```bash
cd 04_https
terraform init
terraform plan          # 5개 리소스 — 인증서·검증 레코드·검증 대기·443 규칙·리스너
terraform apply         # 검증 대기 동안 수 분 블로킹될 수 있음
terraform output https_url
```

1. `cd ../03_real && terraform apply` — 선행 인프라 (이미 올려둔 상태면 생략)
2. `cd ../04_https && terraform init && terraform apply`
3. `terraform output https_url`로 주소 확인 → 브라우저에서 접속
4. Route53 콘솔에서 `cert_validation` 레코드가 자동 생성된 것 확인
5. 정리: `terraform destroy` (인증서·리스너만 삭제, 03 인프라는 그대로)

## 소스 구조

```text
04_https/
├── readme.md
├── versions.tf      # 코어·provider 버전 (03과 동일)
├── providers.tf     # 리전 + default_tags
├── variables.tf     # domain_name + real_state_path
├── main.tf          # remote_state + ACM + 443 규칙 + HTTPS 리스너
└── outputs.tf       # 인증서 ARN + https_url
```

## 파일·디렉터리 역할

- `main.tf`의 `data "terraform_remote_state"`: 03의 state 파일을 읽는 창구 — `local.real.alb_arn`처럼 outputs만 읽을 수 있음 (리소스 자체는 못 건드림)
- `aws_security_group_rule`: 03이 만든 SG에 규칙만 추가 — SG 소유는 03, 규칙 소유는 04 (destroy 시 규칙만 사라짐)
- `aws_lb_listener.https`: 03의 ALB에 리스너 부착 — 03의 80 리스너와 공존 (HTTP도 계속 동작)

## 단계 간 연결

03_real의 outputs(`alb_arn`·`alb_sg_id`·`alb_target_group_arn`·`route53_zone_id`) → 04의 remote_state 입력. 03에 이 출력들이 없으면 plan 실패 — 먼저 03을 최신 코드로 apply해야 합니다.

## 산출물

- ACM 인증서 (`app.<도메인>`, DNS 검증)
- Route53 검증 레코드 + 발급 완료 대기
- ALB SG의 443 인바운드 규칙
- ALB의 HTTPS 리스너 → 03의 타깃그룹

## 완료 기준

- [ ] `terraform plan`이 remote_state를 읽고 5개 리소스 계획을 세움
- [ ] apply 후 `https://app.<도메인>`으로 접속됨 (존 위임 완료 시)
- [ ] `terraform destroy` 후에도 03의 ALB·존이 그대로 남아 있음
- [ ] HTTP 리스너가 forward 그대로라 80 포트도 계속 열린다는 것을 설명할 수 있음 — 리다이렉트를 원하면 03의 리스너 코드를 바꿔야 함 (별도 state로는 못 바꿈)
