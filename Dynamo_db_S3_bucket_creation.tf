module "versioning" {
	source = "./Modules/cred"
}

terraform {
	required_providers {
		aws = {
			source = "hashicorp/aws"
			version = "4.67.0"
		}
	}
}

provider "aws" {
	region = "us-east-1"
} 

resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for DynamoDB"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"
        }
        Action = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource aws_dynamodb_table "dynamodb_table" {
  name         = "dynamo-db-table-terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
	name = "LockID"
	type = "S"
  }
  tags = {
  Environment = "Production"
  ManagedBy   = "Terraform"
	}
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }
  point_in_time_recovery {
  enabled = true
}
}

resource "aws_sns_topic" "terraform_state_notifications" {
  name = "terraform-state-notifications"
  kms_master_key_id = aws_kms_key.sns.arn
}

resource "aws_kms_key" "sns" {
  description         = "KMS key for SNS topic"
  enable_key_rotation = true
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.terraform_state_notifications.arn
  protocol  = "email"
  endpoint  = "your-email@example.com"
}

resource "aws_sns_topic_policy" "allow_s3_publish" {
  arn = aws_sns_topic.terraform_state_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowS3Publish"
        Effect = "Allow"

        Principal = {
          Service = "s3.amazonaws.com"
        }

        Action = "SNS:Publish"

        Resource = aws_sns_topic.terraform_state_notifications.arn

        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_s3_bucket.bucket.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "terraform_state_notification" {
  bucket = aws_s3_bucket.bucket.id

  topic {
    topic_arn = aws_sns_topic.terraform_state_notifications.arn

    events = [
      "s3:ObjectCreated:*"
    ]

    filter_suffix = ".tfstate"
  }

  depends_on = [
    aws_sns_topic_policy.allow_s3_publish
  ]
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "logging" {
  bucket = aws_s3_bucket.bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "logs/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "life" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    id     = "cleanup"
    status = "Enabled"

    expiration {
      days = 30
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "s3-bucket-terraform-state-file-storing"
}

resource "aws_s3_bucket_ownership_controls" "bucket_ownership" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.bucket_ownership]

  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}
