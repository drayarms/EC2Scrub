variable "aws_vpc_id" {
  description = "VPC ID from the network module"
  type = string
}

variable "aws_private_subnet_id0" {
  description = "Subnet ID from the network module"
  type = string
}

variable "aws_private_subnet_id1" {
  description = "Subnet ID from the network module"
  type = string
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

