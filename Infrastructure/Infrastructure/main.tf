provider "aws"{
	region = var.region
}

module "network"{
	source = "./Modules/Network"
}

module "compute"{
	source = "./Modules/Compute"

	#Default values of variables defined in variables.tf
	aws_vpc_id = module.network.vpc_id # Assign variable to vpc_id output from network module
	aws_private_subnet_ids = module.network.private_subnet_ids
	lambda_source_path = "${path.root}/../../Application/lambda_function.py"
	lambda_name = "ec2-inventory-lambda"
	lambda_handler = "lambda_function.lambda_handler" #lambda_function is name of python src file and lambda_handler is func name
}
