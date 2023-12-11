resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_config.vpc_cidr_block
  enable_dns_support = true
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.environment}-vpc"
    Environment = var.environment
  }
}

# Create public subnets dynamically based on the list of CIDR blocks
resource "aws_subnet" "public_subnet" {
  count = length(var.vpc_config.public_subnet_cidr_blocks) > 0 ? length(var.vpc_config.public_subnet_cidr_blocks) : 0
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.vpc_config.public_subnet_cidr_blocks[count.index]
  availability_zone       = var.vpc_config.subnet_availability_zones[count.index] # Specify the desired availability zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}_public_subnet${count.index + 1}"
    Environment : var.environment
  }
}


# Create private subnets dynamically based on the list of CIDR blocks
resource "aws_subnet" "private_subnet" {
  count = length(var.vpc_config.private_subnet_cidr_blocks) > 0 ? length(var.vpc_config.private_subnet_cidr_blocks) : 0

  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.vpc_config.private_subnet_cidr_blocks[count.index]
  availability_zone       = var.vpc_config.subnet_availability_zones[count.index] # Specify the desired availability zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.environment}_private_subnet${count.index + 1}"
    Environment : var.environment
  }
}

# Create an Internet Gateway for the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# Create a default route for the public subnet to the Internet Gateway
resource "aws_route_table" "public_route_table" {
  count = length(var.vpc_config.public_subnet_cidr_blocks) > 0 ? length(var.vpc_config.public_subnet_cidr_blocks) : 0

  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "public-route-table-${count.index + 1}"
  }
}

resource "aws_route" "public_route" {
  count = length(var.vpc_config.public_subnet_cidr_blocks) > 0 ? length(var.vpc_config.public_subnet_cidr_blocks) : 0

  route_table_id         = aws_route_table.public_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Create a default route table association for the public subnet to the Internet Gateway


resource "aws_route_table_association" "public_association" {
  count = length(var.vpc_config.public_subnet_cidr_blocks) > 0 ? length(var.vpc_config.public_subnet_cidr_blocks) : 0

  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table[count.index].id
}


# Create route tables for private subnets
resource "aws_route_table" "private_route_table" {
  count = length(var.vpc_config.private_subnet_cidr_blocks) > 0 ? length(var.vpc_config.private_subnet_cidr_blocks) : 0

  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.environment}-private-route-table-${count.index + 1}"
  }
}

# Create Elastic IP(s)
resource "aws_eip" "nat_gateway_eip" {
  count = var.vpc_config.create_one_nat_gateway ? 1 : length(var.vpc_config.private_subnet_cidr_blocks)
  tags = {
    Name = var.vpc_config.create_one_nat_gateway ? "nat-gateway-eip" : "nat-gateway-eip-${count.index + 1}"
  }
  #instance = var.vpc_config.create_one_nat_gateway ? aws_instance.dummy[0].id : aws_instance.dummy[count.index].id
}

# Create NAT Gateway(s)
resource "aws_nat_gateway" "public_nat" {
  count = var.vpc_config.create_one_nat_gateway ? 1 : length(var.vpc_config.private_subnet_cidr_blocks)

  subnet_id = var.vpc_config.create_one_nat_gateway ? aws_subnet.public_subnet[0].id : aws_subnet.public_subnet[count.index].id
  allocation_id = aws_eip.nat_gateway_eip[var.vpc_config.create_one_nat_gateway ? 0 : count.index].id

  tags = {
    Name = var.vpc_config.create_one_nat_gateway ? "nat-gateway" : "nat-gateway-${count.index + 1}"
  }
}

# Create default routes for private subnets to the NAT Gateways
resource "aws_route" "private_route" {
  count = length(var.vpc_config.private_subnet_cidr_blocks) > 0 ? length(var.vpc_config.private_subnet_cidr_blocks) : 0

  route_table_id         = aws_route_table.private_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.public_nat[var.vpc_config.create_one_nat_gateway ? 0 : count.index].id
}

# Associate route tables with the subnets
resource "aws_route_table_association" "private_association" {
  count = length(var.vpc_config.private_subnet_cidr_blocks) > 0 ? length(var.vpc_config.private_subnet_cidr_blocks) : 0

  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

# Security Group
resource "aws_security_group" "sg" {
  count       = length(var.security_groups)
  name        = var.security_groups[count.index].name
  description = var.security_groups[count.index].description
  vpc_id      = aws_vpc.main_vpc.id

  dynamic "ingress" {
    for_each = var.security_groups[count.index].ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.security_groups[count.index].egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }

  tags = {
    Name        = "${var.environment}-${var.security_groups[count.index].name}"
    Environment = var.environment
  }
}

# ... (existing code)

