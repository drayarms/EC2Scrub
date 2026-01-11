output "vpc_id"{
	value = aws_vpc.my_vpc.id # We want to pass this to root module so that lambda in compute module can be config'd with it
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id # We want to pass this to root module so that lambda in compute module can be config'd with it
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id # We want to pass this to root module so that lambda in compute module can be config'd with it
}
