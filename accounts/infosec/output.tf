output "cloudtrail_bucket_id" {
  value = aws_s3_bucket.cloudtrail.id
}

output "account_alias" {
  value = aws_iam_account_alias.alias.account_alias
}
