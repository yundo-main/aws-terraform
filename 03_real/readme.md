# 03_real — Terraform 실전 (변수·표준 레이아웃)

`02_practice`의 인프라 전체를 표준 레이아웃·변수화·단일 state로 재구성한 단계입니다.

## 학습 목표

- versions/providers/variables/main/outputs 표준 레이아웃을 안다
- 하드코딩된 값을 변수로 추출하고 `var.xxx`로 참조할 수 있다
- `dynamic` 블록으로 반복되는 설정을 줄일 수 있다
- `sensitive` 변수와 default_tags 같은 실전 패턴을 안다

## 핵심 내용

- versions.tf — terraform/provider 버전 고정
- providers.tf — 리전 변수 참조 + default_tags 공통 태그
- variables.tf — 네트워크·EC2·RDS 값 전부 변수화
- main.tf — 02 전체 리소스 (섹션 주석이 02의 파일 번호와 1:1 대응)
- outputs.tf — vpc_id·서브넷·배스천 IP·RDS 엔드포인트
- origin/ — 변수화 전 원본 (01~09 .tf, diff 비교용)

## 이론적 배경

02_practice는 state 분리(계층별 수명주기)를 배우는 구조였다면, 03_real은 하나의 state 안에서 코드를 정리하는 방식입니다. 같은 리소스를 만들지만 값은 변수로, 태그는 default_tags로, 반복 파라미터는 dynamic 블록으로 표준화했습니다. 실무는 둘을 조합합니다 — 계층별 state 분리 + 각 계층 내부는 변수·모듈화.

## 실습

```bash
terraform init
terraform plan -var="db_password=YourPass123"   # db_password는 필수 입력
terraform apply -var="db_password=YourPass123"
```

```bash
terraform plan -var-file="dev.tfvars"   # 환경별 tfvars 파일 사용
```

1. `origin/` 원본과 `main.tf`를 비교 — 하드코딩 → `var.xxx` 변경점 찾기
2. `variables.tf`의 default를 바꿔 plan 차이 확인
3. `-var` / `-var-file`로 같은 코드로 다른 환경 만들기
4. 파라미터 그룹의 `dynamic` 블록과 원본 반복 선언 비교

## 소스 구조

```text
03_real/
├── readme.md
├── versions.tf       # terraform >= 1.6, aws ~> 5.0
├── providers.tf      # provider "aws" (var.aws_region) + default_tags
├── variables.tf      # 입력 변수 — 리전·CIDR·EC2·RDS 전체
├── main.tf           # 02 전체 리소스 — var 참조로 변수화 (섹션 = 02 파일명)
├── slides/           # 이론 슬라이드 9장 (s01~s09)
├── outputs.tf        # vpc_id·서브넷·배스천 IP·RDS 엔드포인트
└── origin/           # 02 원본 .tf 9개 — 비교용 보관
```

## 파일·디렉터리 역할

| 경로 | 역할 |
| --- | --- |
| `versions.tf` | 버전 제약 — 재현성 |
| `providers.tf` | 리전 + `default_tags`로 모든 리소스에 공통 태그 |
| `variables.tf` | `db_password`는 `sensitive` + 기본값 없음 (필수 입력) |
| `main.tf` | 리소스 이름은 02와 동일 — state 대조 가능 |
| `origin/` | 리팩터링 전 원본 — `diff` 비교용 |

## 단계 간 연결

02의 원본 파일들이 `origin/`에 보존되어 있습니다. `diff -u origin/02_vpc.tf main.tf` 같은 비교로 변수화 과정을 학습할 수 있습니다.

## 산출물

- 변수화된 단일-state Terraform 프로젝트
- 원본과의 diff를 통한 리팩터링 이해

## 완료 기준

- [ ] 5개 표준 파일의 역할을 설명할 수 있다
- [ ] `default_tags`와 리소스별 tags 관계를 안다
- [ ] `sensitive` 변수와 필수 입력 변수를 구분할 수 있다
- [ ] `dynamic` 블록이 반복을 줄이는 원리를 안다
