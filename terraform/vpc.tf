#VPC
resource "aws_vpc" "ecs_cluster_vpc" {
  cidr_block = var.vpc_cidr_range

  tags = {
    Name        = var.vpc_name
    environment = var.env
    created_by  = local.created_by
  }
}

#Public Subnets
resource "aws_subnet" "ecs_cluster_vpc_public_subnets" {
  vpc_id = aws_vpc.ecs_cluster_vpc.id

  count      = length(var.public_subnet_cidrs)
  cidr_block = element(var.public_subnet_cidrs, count.index)

  availability_zone = element(var.azs, count.index)

  map_public_ip_on_launch = true

  tags = {
    Name        = join("-", [var.public_subnet_name, count.index + 1])
    environment = var.env
    created_by  = local.created_by
  }
}

#Private Subnets
resource "aws_subnet" "ecs_cluster_vpc_private_subnets" {
  vpc_id = aws_vpc.ecs_cluster_vpc.id

  count      = length(var.private_subnet_cidrs)
  cidr_block = element(var.private_subnet_cidrs, count.index)

  availability_zone = element(var.azs, count.index)

  tags = {
    Name        = join("-", [var.private_subnet_name, count.index + 1])
    environment = var.env
    created_by  = local.created_by
  }
}

#Internet Gateway
resource "aws_internet_gateway" "ecs_cluster_vpc_internet_gw" {
  vpc_id = aws_vpc.ecs_cluster_vpc.id

  tags = {
    Name        = var.internet_gateway
    environment = var.env
    created_by  = local.created_by
  }
}

#Route table for the public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.ecs_cluster_vpc.id

  tags = {
    Name        = var.public_route_table
    environment = var.env
    created_by  = local.created_by
  }
}

#Route associated to the public route table
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = var.public_destination_cidr_block
  gateway_id             = aws_internet_gateway.ecs_cluster_vpc_internet_gw.id
}

#Route table association
resource "aws_route_table_association" "public_route_table_association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.ecs_cluster_vpc_public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}

#Elastic IP Address
resource "aws_eip" "nat_gateway_eip" {
  count = length(var.private_subnet_cidrs)
  vpc   = true
}

#Nat Gateway
resource "aws_nat_gateway" "ecs_vpc_nat_gateway" {
  count         = length(var.private_subnet_cidrs)
  allocation_id = element(aws_eip.nat_gateway_eip.*.id, count.index)
  subnet_id     = element(aws_subnet.ecs_cluster_vpc_private_subnets.*.id, count.index)
  depends_on    = [aws_internet_gateway.ecs_cluster_vpc_internet_gw]
}

#Private Route Table
resource "aws_route_table" "private_route_table" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.ecs_cluster_vpc.id
}

#Route associated to the private route table 
resource "aws_route" "private_route" {
  count                  = length(compact(var.private_subnet_cidrs))
  route_table_id         = element(aws_route_table.private_route_table.*.id, count.index)
  destination_cidr_block = var.private_destination_cidr_block
  nat_gateway_id         = element(aws_nat_gateway.ecs_vpc_nat_gateway.*.id, count.index)
}

#Route table association
resource "aws_route_table_association" "private_route_table_association" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.ecs_cluster_vpc_private_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.private_route_table.*.id, count.index)
}

#Security group for alb
resource "aws_security_group" "ecs_alb_sg" {
  name   = join("-", [var.alb_security_group, var.env])
  vpc_id = aws_vpc.ecs_cluster_vpc.id

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

#Security group for ecs
resource "aws_security_group" "ecs_tasks" {
  name   = join("-", [var.ecs_security_group, var.env])
  vpc_id = aws_vpc.ecs_cluster_vpc.id

  ingress {
    protocol         = "tcp"
    from_port        = var.container_port
    to_port          = var.container_port
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}