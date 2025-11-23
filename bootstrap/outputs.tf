output "state_bucket_name" {
  value = aws_s3_bucket.state.bucket
}

output "plan_bucket_name" {
  value = aws_s3_bucket.plan.bucket
}

output "tfvars_bucket_name" {
  value = aws_s3_bucket.tfvars.bucket
}