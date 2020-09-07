remote_state {
  backend = "s3"
  config = {
    bucket         = "admin-terraform-state.tffw.net"
    key            = "master/organization/terraform.tfstate"
    region         = "us-east-1"
    role_arn       = "arn:aws:iam::${get_env("TG_AWS_ACCT", "${get_aws_account_id()}")}:role/OrganizationAccountAccessRole"
    encrypt        = true
    dynamodb_table = "admin-terraform-lock"
    s3_bucket_tags = {
      owner = "terragrunt"
      name  = "Terraform state storage"
    }
    dynamodb_table_tags = {
      owner = "terragrunt"
      name  = "Terraform lock table"
    }
  }
}

terraform {
  extra_arguments "shared_vars" {
    commands = get_terraform_commands_that_need_vars()
    optional_var_files = [
      "${find_in_parent_folders("shared.hcl", "ignore")}",
      "${get_parent_terragrunt_dir()}/shared.hcl"
    ]
  }
}
