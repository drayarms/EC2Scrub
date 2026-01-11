#Terraform cannot use an S3 backend until after the bucket and DynamoDB table already exist. 
#This is why the backend must read the local state of the Backend module first (the bootstrap step).

terraform {
	backend "s3" {
		bucket =  "ec2-scrub-infrastructure-state-bucket" # Reference from backend module
		key = "global/terraform.tfstate" # Path to file inside the S3 bucket
		region = "us-west-1"
		dynamodb_table = "ec2-scrub-terraform-lock" # Reference from backend module
		encrypt = true
	}
}

data "terraform_remote_state" "backend" {
	backend = "local"
	config = {
		path = "../Backend/terraform.tfstate" # Path to local state created when running Backend first
	}
}
