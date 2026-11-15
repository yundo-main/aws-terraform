# ============================================================
# providers.tf — provider + 공통 태그
# - default_tags: 여기 선언한 태그가 모든 리소스에 자동 적용
#   리소스별 tags와 병합되며, 리소스 태그가 같은 키면 우선
# ============================================================

provider "aws" {
  region = var.aws_region # Asia Pacific (Seoul)

  default_tags {
    tags = {
      Project = var.project_name
      Managed = "terraform"
    }
  }
}
