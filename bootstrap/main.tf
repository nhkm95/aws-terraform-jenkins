locals {
  base_name   = "${var.project}-${var.environment}"
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
      State   = "Local"
    },
    var.extra_tags
  )
}

resource "aws_s3_bucket" "state" {
  bucket = "${var.project}-${var.environment}-${var.state_bucket_name}"
  tags   = local.common_tags
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "state_bucket_name" {
  value = aws_s3_bucket.state.bucket
}