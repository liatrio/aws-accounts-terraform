output "temp_admin_access_key" {
  value = aws_iam_access_key.temp_admin.id
}

output "temp_admin_secret_key" {
  value = aws_iam_access_key.temp_admin.encrypted_secret
}
