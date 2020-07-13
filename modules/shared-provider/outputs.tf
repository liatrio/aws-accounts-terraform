output "provider_role_arn" {
  value = "arn:aws:iam::${local.account_id[var.account]}:role/${var.role}"
}

