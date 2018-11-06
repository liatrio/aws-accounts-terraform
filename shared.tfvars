# must match the terragrunt.remote_state.config in terraform.tfvars
# used by modules that need to read remote state from other modules
terraform_state_bucket = "admin-terraform-state-test103"
terraform_state_bucket_region = "us-east-1"
terraform_state_dynamodb_table = "admin-terraform-lock"

aws_default_region = "us-east-1"
org_name = "fastfeedback"

administrator_default_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
developer_default_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
billing_default_arn = "arn:aws:iam::aws:policy/job-function/Billing"
developer_role_name = "Developer"