# aws-tf

Terraform / IaC 학습용 모듈. `index.html`을 브라우저로 열면 각 단계 포털로 이동할 수 있다.

## 구조

```
aws-tf/
├── index.html             # 루트 포털 — 과정 인덱스
├── readme.md              # 이 파일 — 디렉터리·파일 역할 설명
├── 00_intro/              # 단계 0 — 과정 개요 (IaC·Terraform 개념)
│   ├── index.html         # 단계 포털
│   ├── readme.md          # 단계 문서
│   ├── glossary.md        # 통합 용어집
│   ├── glossary/          # 용어 포털
│   └── slides/            # SVG 슬라이드 9장 (s01~s08)
├── 01_terraform/          # 단계 1 — Terraform 개념·Provider
│   ├── index.html         # 단계 포털
│   ├── readme.md
│   ├── 01-provider.tf     # provider 예제
│   ├── 02-vpc.tf          # VPC 1개 실습
│   ├── 03-outputs.tf      # 출력 예제
│   └── slides/            # SVG 슬라이드 12장 (s01~s12)
├── 02_practice/           # 단계 2 — AWS 실습 (네트워크+컴퓨트)
│   ├── index.html         # 단계 포털
│   ├── readme.md
│   ├── 01-provider.tf     # provider·버전 고정
│   ├── 02~06 *.tf         # 네트워크 (VPC·서브넷·IGW·NGW·라우팅)
│   ├── 07~09 *.tf         # 컴퓨트 (SG·EC2·RDS)
│   ├── 10-outputs.tf      # 전체 출력 — 단일 state
│   ├── check.sh           # 전체 리소스 확인 → report.html
│   └── slides/            # 실행 방법 SVG 17장 (s01~s17)
├── 03_real/               # 단계 3 — 실전 표준 레이아웃
│   ├── index.html         # 단계 포털
│   ├── readme.md
│   ├── versions.tf        # terraform/provider 버전 고정
│   ├── providers.tf       # provider 블록 + default_tags
│   ├── variables.tf       # 입력 변수
│   ├── main.tf            # 전체 리소스 — 섹션 주석이 02 파일 번호와 대응
│   ├── outputs.tf         # 출력 (04_https가 remote_state로 읽는 출력 포함)
│   ├── origin/            # 02 원본 보관 (비교용)
│   └── slides/            # SVG 슬라이드 9장
├── 04_https/              # 단계 4 — HTTPS 확장 (선택, 03 선행 필요)
│   ├── index.html         # 단계 포털
│   ├── readme.md
│   ├── versions.tf / providers.tf / variables.tf
│   ├── main.tf            # remote_state + ACM + 443 규칙 + HTTPS 리스너
│   └── outputs.tf         # 인증서 ARN + https_url
├── 10_gitops_infra/               # 단계 10 — GitHub 인프라 파이프라인 (main 브랜치)
│   ├── index.html         # 단계 포털
│   ├── readme.md
│   └── *.tf + buildspec   # 저장소 계층+파이프라인 — push→plan→승인→apply
├── 11_gitops_app/       # 단계 11 — 앱 배포 파이프라인 (dev 브랜치)
│   ├── index.html         # 단계 포털
│   ├── readme.md
│   ├── app/               # 샘플 앱 — dev 브랜치 push로 배포
│   └── *.tf + buildspec   # ECR·빌드/배포·파이프라인 (connection 공용)
└── .gitignore             # state·pem·캐시 커밋 방지
```


## 디렉터리·파일 역할

| 경로 | 역할 |
| --- | --- |
| `index.html` | 루트 포털 — 단계 카드 + readme/SVG 뷰어 내장 |
| `{단계}/index.html` | 단계 포털 — readme 탭·슬라이드 뷰어·실습 명령 |
| `00_intro/` | 개념 슬라이드 + 통합 용어집 |
| `01_terraform/` | provider 아키텍처·버전·init 이론 |
| `02_practice/` | 네트워크+컴퓨트 단일 state — 파일 번호가 생성 순서 (22개 리소스) |
| `02_practice/check.sh` | AWS CLI로 생성 리소스 조회 → `report.html` |
| `03_real/` | 표준 레이아웃 (versions/providers/variables/main/outputs) |
| `03_real/origin/` | 리팩터링 전 원본 — diff 비교용 |
| `04_https/` | 03의 ALB·존을 remote_state로 읽어 ACM+HTTPS 부착 — 선택 단계 |
| `{단계}/slides/` | sNN-이름.svg 형식 슬라이드 + readme.md (제목 매핑) |

## 주의

- `terraform.tfstate`·`*.pem`은 `.gitignore` 대상 — 커밋 금지
- 실습 리소스(NGW·EC2·RDS)는 과금됨 — 03_real의 EKS까지 올리면 클러스터·노드 비용 추가 — 사용 후 `terraform destroy` (단일 state라 한 번에 삭제)
