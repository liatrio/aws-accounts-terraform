variable "terraform_init_user_name" {
  default = "terraform-init"
}

variable "administrator_default_arn" {}
variable "billing_default_arn" {}
variable "aws_default_region" {}
variable "org_name" {}

variable "terraform_state_bucket" {}
variable "terraform_state_dynamodb_table" {}

variable "infosec_acct_email" {}
variable "prod_acct_email" {}
variable "non_prod_acct_email" {}
