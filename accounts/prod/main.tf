terraform {
  backend "s3" {}
}

data "aws_caller_identity" "current" {
  provider = aws.noassume
}

data "terraform_remote_state" "organization" {
  backend = "s3"

  config = {
    bucket   = var.terraform_state_bucket
    key      = "master/organization/terraform.tfstate"
    region   = var.terraform_state_bucket_region
    role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TerragruntReader"
  }
}

data "terraform_remote_state" "infosec" {
  backend = "s3"

  config = {
    bucket   = var.terraform_state_bucket
    key      = "accounts/infosec/terraform.tfstate"
    region   = var.terraform_state_bucket_region
    role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TerragruntReader"
  }
}

provider "aws" {
  alias  = "noassume"
  region = var.aws_default_region
}

provider "aws" {
  assume_role {
    role_arn = "arn:aws:iam::${data.terraform_remote_state.organization.outputs.prod_acct_id}:role/Administrator"
  }

  region = var.aws_default_region
}

resource "aws_iam_account_alias" "alias" {
  account_alias = "${var.org_name}-prod"
}

resource "aws_cloudtrail" "cloudtrail" {
  name                       = "cloudtrail-prod"
  s3_key_prefix              = "prod"
  s3_bucket_name             = data.terraform_remote_state.infosec.outputs.cloudtrail_bucket_id
  enable_log_file_validation = true
  is_multi_region_trail      = true
}

module "cross_account_role_developer" {
  source                  = "../../modules/cross-account-role"
  assume_role_policy_json = data.terraform_remote_state.organization.outputs.crossaccount_assume_from_infosec_policy_json
  role                    = var.developer_role_name
  role_policy_arn         = var.developer_default_arn
}
