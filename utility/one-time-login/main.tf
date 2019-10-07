terraform {
  backend "local" {}
}

provider "aws" {
  assume_role {
    role_arn = "arn:aws:iam::${var.infosec_acct_id}:role/Administrator"
  }

  region = var.aws_default_region
}

resource "aws_iam_user_login_profile" "login" {
  user    = var.user_name
  pgp_key = "keybase:${var.keybase}"
}
