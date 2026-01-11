variable "vpc_cidr"{
	default = "10.1.0.0/16" 
}

variable "aws_vpc_name"{
	type = string
	default = "Production VPC"
}

variable "aws_igw_name"{
	type = string
	default = "My-IGW"
}

variable "azs"{
	type = list(string)
	default = ["us-west-1a", "us-west-1b"]
}

variable "public_subnet_cidr"{ # Ensure the number of public subnets is a multiple of the number of AZs
	type = list(string)
	default = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidr"{ # Ensure the number of private subnets is a multiple of the number of AZs
	type = list(string)
	default = ["10.1.3.0/24", "10.1.4.0/24"]
}

variable "public_rt_name"{
	type = string
	default = "Public-Route-Table"
}

