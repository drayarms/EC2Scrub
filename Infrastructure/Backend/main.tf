
provider "aws"{
	region = var.region
}

# Create S3 bucket for remote state
resource "aws_s3_bucket" "tf_state" {
	bucket = var.s3_bucket_name
	acl = "private"

	versioning {
		enabled = true
	}

	server_side_encryption_configuration {
		rule {
			apply_server_side_encryption_by_default {
				sse_algorithm = "AES256"
			}
		}
	}
}

# Create DynamoDB table for state locking
resource "aws_dynamodb_table" "tf_lock" {
	name = var.dynamodb_table_name
	billing_mode = "PAY_PER_REQUEST"
	hash_key = "LockID"

	attribute {
		name = "LockID"
		type = "S"
	}
}