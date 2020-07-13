data "aws_caller_identity" "current" {
  provider = aws.noassume
}

data "terraform_remote_state" "organization" {
  backend = "s3"

  config = {
    bucket   = var.terraform_state_bucket
    key      = "master/organization/terraform.tfstate"
    region   = var.terraform_state_bucket_region
    role_arn = "arn:aws:iam::${var.infosec_account_id}:role/TerragruntReader"
  }
}

provider "aws" {
  alias  = "noassume"
  region = var.aws_default_region
}

locals {
  account_id = {
    infosec   = data.terraform_remote_state.organization.outputs.infosec_acct_id
    prod      = data.terraform_remote_state.organization.outputs.prod_acct_id
    non_prod  = data.terraform_remote_state.organization.outputs.non_prod_acct_id
  }
}

