#Outputs form Compute Module
output "lambda_zip_path" {
	value = module.compute.lambda_zip_path
}

#Outputs from Network Module
output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
 }
