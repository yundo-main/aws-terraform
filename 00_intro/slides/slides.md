---
marp: true
theme: default
paginate: true
---

# Terraform
### 코드로 관리하는 인프라 (Infrastructure as Code)

---

## IaC (Infrastructure as Code)

> "인프라를 코드로 관리한다"

- GUI / 웹 콘솔 대신 **코드**로 리소스를 관리
- 두 가지 방식
  - **선언적(Declarative)**: 결과 상태를 정의
  - **명령적(Imperative)**: 수행 절차를 정의
- 대표 도구: Terraform, AWS CloudFormation, Ansible, Chef, Kubernetes Manifests

---

## 프로비저닝 (Provisioning)

> IT 시스템에 필요한 자원을 준비·설정·할당하는 과정

- 서버, 네트워크, 데이터베이스 등
- IaC 도구는 이 과정을 코드로 자동화한다

---

## Terraform이란?

- **HashiCorp**에서 개발한 IaC 도구
- **Manifest**: 무엇을 구축할지 HCL로 작성한 `.tf` 파일
- HCL = HashiCorp Configuration Language (JSON 유사 문법)

```hcl
resource "aws_instance" "web" {
  ami           = "ami-xxxxxxxx"
  instance_type = "t3.micro"
}
```

---

## Terraform 워크플로우

```
init → validate → plan → apply
```

| 단계 | 역할 |
| --- | --- |
| `init` | 작업 디렉터리 초기화, 프로바이더 설치 |
| `validate` | 문법·구성 검증 |
| `plan` | 변경될 내용 미리보기 |
| `apply` | 실제 인프라 생성·변경 |

---

## Terraform의 장점

- **자동화**: 반복 작업 감소, 빠르고 정확한 배포
- **일관성**: 개발·테스트·운영 환경 간 차이 제거
- **멀티 클라우드**: AWS, Azure, GCP, VMware, 온프레미스 지원
- **효율성**: 복잡한 인프라도 빠르게 배포
- **버전 관리**: Git + CI/CD로 변경 이력 추적, 안정적 배포

---

## Ansible vs Terraform

| 구분 | Ansible | Terraform |
| --- | --- | --- |
| 주 용도 | 구성 관리 | 인프라 프로비저닝 |
| 철학 | 서버 안을 어떻게 설정할 것인가 | 인프라를 무엇으로 만들 것인가 |
| 방식 | 절차적 + 선언적 | 선언적 |
| 상태 관리 | 없음 (stateless) | 있음 (stateful) |
| 에이전트 | 불필요 (SSH 기반) | 불필요 |
| 언어 | YAML (Playbook) | HCL |
| 멱등성 | 있음 | 있음 |
| 대표 사용처 | 패키지 설치, 설정 배포, 서비스 재시작 | VM, VPC, LB, DB 생성 |

---

## 정리

- IaC: 인프라를 코드로 관리 → 재현성·자동화 확보
- Terraform: 선언적 IaC 도구, `init → validate → plan → apply`
- Ansible: 서버 **내부 설정**, Terraform: 인프라 **생성**
- 두 도구는 상호 보완적으로 함께 사용되는 경우가 많다
