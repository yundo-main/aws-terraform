# ============================================================
# 00-remote-state.tf — step1의 출력을 읽는 연결부
#   artifact 버킷 이름·ARN을 가져와 locals로 노출
# ============================================================

# remote_state — 다른 step의 출력 읽기
data "terraform_remote_state" "backend" {
  backend = "local"
  config = {
    path = "../step1_backend/terraform.tfstate"
  }
}

locals {
  artifacts_bucket     = data.terraform_remote_state.backend.outputs.artifacts_bucket
  artifacts_bucket_arn = data.terraform_remote_state.backend.outputs.artifacts_bucket_arn
  tfstate_bucket       = data.terraform_remote_state.backend.outputs.tfstate_bucket
  tf_lock_table        = data.terraform_remote_state.backend.outputs.tf_lock_table
}
