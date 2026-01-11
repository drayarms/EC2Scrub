variable "aws_vpc_id" {
  description = "VPC ID from the network module"
  type = string
}

variable "aws_private_subnet_ids" {
	description = "List of private subnet IDs for Lambda"
	type = list(string)
}

variable "lambda_source_path" {
  type = string
}

variable "lambda_name" {
	type = string
}

variable "lambda_handler" {
  description = "Lambda handler in the form <file>.<function>"
  type = string
}

