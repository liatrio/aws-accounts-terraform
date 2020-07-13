terraform {
  backend "local" {}
}

data "terraform_remote_state" "organization" {
  backend = "s3"

  config = {
    bucket   = var.terraform_state_bucket
    key      = "master/organization/terraform.tfstate"
    region   = var.terraform_state_bucket_region
    role_arn = "arn:aws:iam::${var.infosec_acct_id}:role/TerragruntReader"
  }
}

provider "aws" {
  alias = "assume_infosec"

  assume_role {
    role_arn = "arn:aws:iam::${data.terraform_remote_state.organization.outputs.infosec_acct_id}:role/OrganizationAccountAccessRole"
  }

  region = var.aws_default_region
}

provider "aws" {
  alias = "assume_prod"

  assume_role {
    role_arn = "arn:aws:iam::${data.terraform_remote_state.organization.outputs.prod_acct_id}:role/OrganizationAccountAccessRole"
  }

  region = var.aws_default_region
}

provider "aws" {
  alias = "assume_non_prod"

  assume_role {
    role_arn = "arn:aws:iam::${data.terraform_remote_state.organization.outputs.non_prod_acct_id}:role/OrganizationAccountAccessRole"
  }

  region = var.aws_default_region
}

resource "aws_iam_user" "temp_admin" {
  name          = "temp-admin"
  force_destroy = true
  provider      = aws.assume_infosec
}

resource "aws_iam_user_policy_attachment" "assume_role_infosec_admin" {
  user       = aws_iam_user.temp_admin.name
  policy_arn = data.terraform_remote_state.organization.outputs.infosec_admin_role_policy_arn
  provider   = aws.assume_infosec
}

resource "aws_iam_user_policy_attachment" "assume_role_prod_admin" {
  user       = aws_iam_user.temp_admin.name
  policy_arn = data.terraform_remote_state.organization.outputs.prod_admin_role_policy_arn
  provider   = aws.assume_infosec
}

resource "aws_iam_user_policy_attachment" "assume_role_non_prod_admin" {
  user       = aws_iam_user.temp_admin.name
  policy_arn = data.terraform_remote_state.organization.outputs.non_prod_admin_role_policy_arn
  provider   = aws.assume_infosec
}

resource "aws_iam_user_policy_attachment" "assume_role_terragrunt_admin" {
  user       = aws_iam_user.temp_admin.name
  policy_arn = data.terraform_remote_state.organization.outputs.terragrunt_admin_role_policy_arn
  provider   = aws.assume_infosec
}

resource "aws_iam_user_policy_attachment" "assume_role_terragrunt_reader" {
  user       = aws_iam_user.temp_admin.name
  policy_arn = data.terraform_remote_state.organization.outputs.terragrunt_reader_role_policy_arn
  provider   = aws.assume_infosec
}

resource "aws_iam_access_key" "temp_admin" {
  user     = aws_iam_user.temp_admin.name
  pgp_key  = "keybase:${var.keybase}"
  provider = aws.assume_infosec
}
