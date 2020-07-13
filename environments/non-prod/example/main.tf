terraform {
  backend "s3" {
  }
}

module "shared-provider" {
  source                        = "../../../modules/shared-provider"
  terraform_state_bucket_region = var.terraform_state_bucket_region
  aws_default_region            = var.aws_default_region
  terraform_state_bucket        = var.terraform_state_bucket
  infosec_account_id            = var.infosec_account_id
  account                       = var.account
}

provider "aws" {
  assume_role {
    role_arn = module.shared-provider.provider_role_arn
  }

  region = var.aws_default_region
}

data "terraform_remote_state" "infosec" {
  backend = "s3"

  config = {
    bucket   = var.terraform_state_bucket
    key      = "accounts/infosec/terraform.tfstate"
    region   = var.terraform_state_bucket_region
    role_arn = "arn:aws:iam::${var.infosec_account_id}:role/TerragruntReader"
  }
}
