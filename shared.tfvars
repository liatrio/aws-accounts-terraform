# must match the terragrunt.remote_state.config in terraform.tfvars
terraform_state_bucket = "admin-terraform-state-test.your_organization.biz"
terraform_state_bucket_region = "us-east-1"
terraform_state_dynamodb_table = "admin-terraform-lock"

aws_default_region = "us-east-1"
org_name = "your_organization"

infosec_acct_email = "aws.infosec@your_organization.biz"
prod_acct_email = "aws.infosec@your_organization.biz"
non_prod_acct_email = "aws.infosec@your_organization.biz"

administrator_default_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
developer_default_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
billing_default_arn = "arn:aws:iam::aws:policy/job-function/Billing"
developer_role_name = "Developer"