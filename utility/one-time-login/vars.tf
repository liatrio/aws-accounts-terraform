variable "user_name" {
  description = "Enter the user name of the existing user"
}

variable "keybase" {
  description = "Enter the keybase profile to encrypt the temporary password (to decrypt: terraform output temp_password | base64 --decode | keybase pgp decrypt)"
}

variable "infosec_acct_id" {}
variable "aws_default_region" {}
variable "terraform_state_bucket" {}
variable "terraform_state_bucket_region" {}
