variable "region"{
	default = "us-west-1"
}

variable "s3_bucket_name"{
	default = "ec2-scrub-infrastructure-state-bucket"
}

variable "dynamodb_table_name"{
	default = "ec2-scrub-terraform-lock"
}