#VPC
resource "aws_vpc" "my_vpc"{
	cidr_block = var.vpc_cidr
	tags = {
		Name = var.aws_vpc_name
	}
}

#Subnets: Public
resource "aws_subnet" "public"{
	count = length(var.public_subnet_cidr)
	vpc_id = aws_vpc.my_vpc.id
	cidr_block = element(var.public_subnet_cidr, count.index)
	availability_zone = element(var.azs, count.index)
	tags = {
		Name = "My-public-subnet-${count.index + 1}"
	}
}

#Subnets: Private
resource "aws_subnet" "private" {
	count = length(var.private_subnet_cidr)
	vpc_id = aws_vpc.my_vpc.id
	cidr_block = element(var.private_subnet_cidr, count.index)
	availability_zone = element(var.azs, count.index)

	tags = {
		Name = "My-private-subnet-${count.index + 1}"
	}
}

#IGW
resource "aws_internet_gateway" "my_igw"{
	vpc_id = aws_vpc.my_vpc.id
	tags = {
		Name = var.aws_igw_name
	}
}

#Route Table: Attach IGW
resource "aws_route_table" "public"{
	vpc_id = aws_vpc.my_vpc.id
	route{
		cidr_block = "0.0.0.0/0" # All IP ranges ie the entire internet
		gateway_id = aws_internet_gateway.my_igw.id
	}
	tags = {
		Name = var.public_rt_name
	}
}

#Public Route Table Association with Public Subnets
resource "aws_route_table_association" "my_rt_association"{
	count = length(var.public_subnet_cidr)
	subnet_id = aws_subnet.public[count.index].id
	route_table_id = aws_route_table.public.id
}

resource "aws_eip" "my_nat_eip" {
	count  = length(var.public_subnet_cidr)
	domain = "vpc"

	tags = {
		Name = "nat-eip-${count.index + 1}"
	}
}

#NAT Gateway (Lives in Public Subnet)
resource "aws_nat_gateway" "my_nat_gateway" {
	count = length(var.public_subnet_cidr)  
	allocation_id = aws_eip.my_nat_eip[count.index].id
	subnet_id = aws_subnet.public[count.index].id

	depends_on = [aws_internet_gateway.my_igw]

	tags = {
		Name = "My-NAT-Gateway-${count.index + 1}"
	}
}

#Private Route Table to NAT Gateway. Each private subnet points to its local NAT Gateway
resource "aws_route_table" "private" {
	count = length(var.private_subnet_cidr) 
	vpc_id = aws_vpc.my_vpc.id

	route {
		cidr_block     = "0.0.0.0/0"
		nat_gateway_id = aws_nat_gateway.my_nat_gateway[count.index].id
	}

	tags = {
		Name = "private-rt-${var.private_subnet_cidr[count.index]}"
	}
}

#Private Route Table Association with Private Subnets
resource "aws_route_table_association" "private" {
	count = length(var.private_subnet_cidr)
	subnet_id = aws_subnet.private[count.index].id
	route_table_id = aws_route_table.private[count.index].id
}

