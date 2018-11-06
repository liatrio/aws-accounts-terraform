output "cloudtrail_bucket_id" {
  value = "${aws_s3_bucket.cloudtrail.id}"
}
