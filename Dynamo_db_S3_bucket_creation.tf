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

resource aws_dynamodb_table "dynamodb_table" {
  name         = "dynamodb-table-terraform-state-locking"
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
}

resource "aws_s3_bucket" "bucket" {
  bucket = "s3-bucket-2026-terraform-state-file"
}

resource "aws_s3_bucket_ownership_controls" "bucket_ownership" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.bucket_ownership]

  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}
