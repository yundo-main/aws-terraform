# aws-tf

Terraform / IaC 학습용 모듈. `index.html`을 브라우저로 열면 각 단계 포털로 이동할 수 있다.

## 구조

```
aws-tf/
├── index.html             # 루트 포털 — 과정 인덱스 (생성기 산출물)
├── readme.md              # 이 파일 — 디렉터리·파일 역할 설명
├── 00_intro/              # 단계 0 — 과정 개요 (IaC·Terraform 개념)
│   ├── index.html         # 단계 포털
│   ├── readme.md          # 단계 문서
│   ├── glossary.md        # 통합 용어집 (생성기 산출물)
│   ├── glossary/          # 용어 포털
│   └── slides/            # SVG 슬라이드 8장 (s01~s08)
├── 01_terraform/          # 단계 1 — Terraform 개념·Provider
│   ├── index.html         # 단계 포털
│   ├── readme.md
│   ├── 01_provider.tf     # provider 예제
│   └── slides/            # SVG 슬라이드 9장 (s01~s09)
├── 02_practice/           # 단계 2 — AWS 실습 (단계별 디렉터리 실행)
│   ├── index.html         # 단계 포털
│   ├── readme.md
│   ├── check.sh           # 전체 리소스 확인 → report.html
│   ├── step1_network/     # VPC·서브넷·IGW·NGW·라우팅 (독립 state)
│   ├── step2_compute/     # SG·EC2·RDS (remote_state → step1)
│   ├── step3_eks/         # EKS·노드그룹·ECR (remote_state → step1)
│   ├── step4_alb/         # Route53·ACM·ALB (작성 예정)
│   └── slides/            # 실행 방법 SVG 11장 (s01~s11)
├── 03_real/               # 단계 3 — 실전 표준 레이아웃
│   ├── index.html         # 단계 포털
│   ├── readme.md
│   ├── versions.tf        # terraform/provider 버전 고정
│   ├── providers.tf       # provider 블록 + default_tags
│   ├── variables.tf       # 입력 변수
│   ├── main.tf            # 리소스 선언
│   ├── outputs.tf         # 출력
│   └── origin/            # 02 원본 보관 (비교용)
├── .agents/               # 에이전트용 설정·템플릿 (학생 배포 제외)
│   ├── gen/               # 포털 생성기 (ref 기반 커스터마이즈)
│   ├── _template/         # 슬라이드·포털 재생산 템플릿
│   ├── {NN}/GUIDE.md      # 단계별 제작 가이드
│   ├── docs/              # 슬라이드 원본 문서
│   └── logs/              # 작업 로그 (타임스탬프.md)
└── .gitignore             # state·pem·캐시 커밋 방지
```

## 포털 생성 (재생성 절차)

`index.html`과 각 단계 `index.html`은 생성기 산출물이다 — readme 수정 후 재생성:

```bash
cd .agents/gen
python3 gen_portal.py     # 01~03 단계 포털
python3 gen_intro.py      # 00_intro 포털
python3 gen_index.py      # 루트 포털
python3 gen_glossary.py   # 용어집 (00_intro/glossary/)
```

## 디렉터리·파일 역할

| 경로 | 역할 |
| --- | --- |
| `index.html` | 루트 포털 — 단계 카드 + readme/SVG 뷰어 내장 |
| `{단계}/index.html` | 단계 포털 — readme 탭·슬라이드 뷰어·실습 명령 |
| `00_intro/` | 개념 슬라이드 + 통합 용어집 |
| `01_terraform/` | provider 아키텍처·버전·init 이론 |
| `02_practice/` | AWS 실습 — stepN 디렉터리별 독립 apply |
| `02_practice/step1_network/` | 네트워크 계층 — outputs로 상위 단계에 ID 전달 |
| `02_practice/step2_compute/` | EC2·RDS — `00-remote-state.tf`로 step1 참조 |
| `02_practice/step3_eks/` | EKS 클러스터·노드그룹·ECR |
| `02_practice/step4_alb/` | Route53·ACM·ALB (빈 파일) |
| `02_practice/check.sh` | AWS CLI로 생성 리소스 조회 → `report.html` |
| `03_real/` | 표준 레이아웃 (versions/providers/variables/main/outputs) |
| `03_real/origin/` | 리팩터링 전 원본 — diff 비교용 |
| `.agents/gen/` | 포털 생성기 — `project-portal.html`이 CSS/JS 마스터 |
| `.agents/_template/` | SVG 슬라이드 규격·프롬프트 (spec/prompts) |
| `.agents/logs/` | 타임스탬프 작업 로그 |
| `{단계}/slides/` | sNN-이름.svg 형식 슬라이드 + readme.md (제목 매핑) |

## 주의

- `terraform.tfstate`·`*.pem`은 `.gitignore` 대상 — 커밋 금지
- 실습 리소스(NGW·EC2·RDS·EKS)는 과금됨 — 사용 후 `terraform destroy` (step4 → step1 역순)
- `.agents/`는 강사용 — 학생에게 배포하지 않는다
