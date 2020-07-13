output "master_acct_id" {
  value = data.aws_caller_identity.current.account_id
}

output "account_alias" {
  value = aws_iam_account_alias.alias.account_alias
}

output "infosec_acct_id" {
  value = aws_organizations_account.infosec.id
}

output "prod_acct_id" {
  value = aws_organizations_account.prod.id
}

output "non_prod_acct_id" {
  value = aws_organizations_account.non_prod.id
}

output "crossaccount_assume_from_infosec_policy_json" {
  value = data.aws_iam_policy_document.crossaccount_assume_from_infosec.json
}

output "master_billing_role_policy_arn" {
  value = module.assume_role_policy_master_billing.policy_arn
}

output "infosec_admin_role_policy_arn" {
  value = module.assume_role_policy_infosec_admin.policy_arn
}

output "prod_admin_role_policy_arn" {
  value = module.assume_role_policy_prod_admin.policy_arn
}

output "non_prod_admin_role_policy_arn" {
  value = module.assume_role_policy_non_prod_admin.policy_arn
}

output "terragrunt_admin_role_policy_arn" {
  value = module.assume_role_policy_terragrunt_admin.policy_arn
}

output "terragrunt_reader_role_policy_arn" {
  value = module.assume_role_policy_terragrunt_reader.policy_arn
}
