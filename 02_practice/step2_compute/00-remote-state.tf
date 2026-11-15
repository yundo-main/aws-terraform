# ============================================================
# step1_network의 state를 읽어온다
# — 같은 리소스를 다시 만들지 않고 ID만 참조
# ============================================================
data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "../step1_network/terraform.tfstate"
  }
}

locals {
  vpc_id           = data.terraform_remote_state.network.outputs.vpc_id
  pub_subnet_2a_id = data.terraform_remote_state.network.outputs.pub_subnet_2a_id
  pub_subnet_2c_id = data.terraform_remote_state.network.outputs.pub_subnet_2c_id
  pri_subnet_2a_id = data.terraform_remote_state.network.outputs.pri_subnet_2a_id
  pri_subnet_2c_id = data.terraform_remote_state.network.outputs.pri_subnet_2c_id
}
