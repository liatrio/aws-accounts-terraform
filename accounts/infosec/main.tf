# SEE users.tf FOR IAM USER ACCOUNTS
terraform {
  backend "s3" {}
}

data "aws_caller_identity" "current" {
  provider = "aws.noassume"
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

provider "aws" {
  alias  = "noassume"
  region = var.aws_default_region
}

provider "aws" {
  assume_role {
    role_arn = "arn:aws:iam::${data.terraform_remote_state.organization.outputs.infosec_acct_id}:role/Administrator"
  }

  region = var.aws_default_region
}

resource "aws_iam_account_alias" "alias" {
  account_alias = "${var.org_name}-infosec"
}

# CLOUD TRAIL
data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid = "CloudTrailAclCheck"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
    ]

    resources = [
      "arn:aws:s3:::${var.cloudtrail_bucket_name}",
    ]
  }

  statement {
    sid = "CloudTrailWrite"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${var.cloudtrail_bucket_name}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control",
      ]
    }
  }
}

resource "aws_s3_bucket" "cloudtrail" {
  policy = data.aws_iam_policy_document.cloudtrail_bucket.json
  bucket = var.cloudtrail_bucket_name
  acl    = "log-delivery-write"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_cloudtrail" "cloudtrail" {
  name                       = "cloudtrail-infosec"
  s3_key_prefix              = "infosec"
  s3_bucket_name             = aws_s3_bucket.cloudtrail.id
  enable_log_file_validation = true
  is_multi_region_trail      = true
}

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 8
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 60
}

# GROUPS
resource "aws_iam_group" "master_billing" {
  name = "MasterBilling"
}

resource "aws_iam_group_policy_attachment" "master_billing" {
  group      = aws_iam_group.master_billing.name
  policy_arn = data.terraform_remote_state.organization.outputs.master_billing_role_policy_arn
}

resource "aws_iam_group" "infosec_admins" {
  name = "InfosecAdmins"
}

resource "aws_iam_group_policy_attachment" "infosec_admins_administrator" {
  group      = aws_iam_group.infosec_admins.name
  policy_arn = data.terraform_remote_state.organization.outputs.infosec_admin_role_policy_arn
}

resource "aws_iam_group_policy_attachment" "infosec_admins_terragrunt_admin" {
  group      = aws_iam_group.infosec_admins.name
  policy_arn = data.terraform_remote_state.organization.outputs.terragrunt_admin_role_policy_arn
}

resource "aws_iam_group_policy_attachment" "infosec_admins_terragrunt_reader" {
  group      = aws_iam_group.infosec_admins.name
  policy_arn = data.terraform_remote_state.organization.outputs.terragrunt_reader_role_policy_arn
}

resource "aws_iam_group" "prod_admins" {
  name = "ProdAdmins"
}

resource "aws_iam_group_policy_attachment" "prod_admins_administrator" {
  group      = aws_iam_group.prod_admins.name
  policy_arn = data.terraform_remote_state.organization.outputs.prod_admin_role_policy_arn
}

resource "aws_iam_group_policy_attachment" "prod_admins_terragrunt_admin" {
  group      = aws_iam_group.prod_admins.name
  policy_arn = data.terraform_remote_state.organization.outputs.terragrunt_admin_role_policy_arn
}

resource "aws_iam_group_policy_attachment" "prod_admins_terragrunt_reader" {
  group      = aws_iam_group.prod_admins.name
  policy_arn = data.terraform_remote_state.organization.outputs.terragrunt_reader_role_policy_arn
}

resource "aws_iam_group" "non_prod_admins" {
  name = "NonProdAdmins"
}

resource "aws_iam_group_policy_attachment" "non_prod_admins_administrator" {
  group      = aws_iam_group.non_prod_admins.name
  policy_arn = data.terraform_remote_state.organization.outputs.non_prod_admin_role_policy_arn
}

resource "aws_iam_group_policy_attachment" "non_prod_admins_terragrunt_admin" {
  group      = aws_iam_group.non_prod_admins.name
  policy_arn = data.terraform_remote_state.organization.outputs.terragrunt_admin_role_policy_arn
}

resource "aws_iam_group_policy_attachment" "non_prod_admins_terragrunt_reader" {
  group      = aws_iam_group.non_prod_admins.name
  policy_arn = data.terraform_remote_state.organization.outputs.terragrunt_reader_role_policy_arn
}

resource "aws_iam_group" "prod_developers" {
  name = "ProdDevelopers"
}

module "assume_role_policy_prod_developers" {
  source       = "../../modules/assume-role-policy"
  account_name = "prod"
  account_id   = data.terraform_remote_state.organization.outputs.prod_acct_id
  role         = var.developer_role_name
}

resource "aws_iam_group_policy_attachment" "prod_developers_developer" {
  group      = aws_iam_group.prod_developers.name
  policy_arn = module.assume_role_policy_prod_developers.policy_arn
}

resource "aws_iam_group" "non_prod_developers" {
  name = "NonProdDevelopers"
}

module "assume_role_policy_non_prod_developers" {
  source       = "../../modules/assume-role-policy"
  account_name = "non-prod"
  account_id   = data.terraform_remote_state.organization.outputs.non_prod_acct_id
  role         = var.developer_role_name
}

resource "aws_iam_group_policy_attachment" "non_prod_developers_developer" {
  group      = aws_iam_group.non_prod_developers.name
  policy_arn = module.assume_role_policy_non_prod_developers.policy_arn
}

data "aws_iam_policy_document" "change_own_credentials" {
  statement {
    sid = "ReadUsersAndPassPolicy"

    actions = [
      "iam:ListUsers",
      "iam:GetAccountPasswordPolicy",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "ChangeOwnCredentials"

    actions = [
      "iam:*AccessKey*",
      "iam:ChangePassword",
      "iam:GetUser",
      "iam:*ServiceSpecificCredential*",
      "iam:*SigningCertificate*",
    ]

    resources = [
      "arn:aws:iam::*:user/&{aws:username}",
    ]
  }
}

resource "aws_iam_policy" "change_own_credentials" {
  name   = "ChangeOwnCredentials"
  path   = "/"
  policy = data.aws_iam_policy_document.change_own_credentials.json
}

resource "aws_iam_group" "all_iam_users" {
  name = "AllIamUsers"
}

resource "aws_iam_group_policy_attachment" "all_iam_users" {
  group      = aws_iam_group.all_iam_users.name
  policy_arn = aws_iam_policy.change_own_credentials.arn
}
