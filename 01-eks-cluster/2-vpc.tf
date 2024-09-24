# Prepare main VPC for EKS cluster
resource "aws_vpc" "vpc_eks" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.eks_cluster_name
  }
}

# Create public subnets for external access
resource "aws_subnet" "vpc_public_subnets" {
  for_each = var.aws_vpc_public_subnets

  vpc_id                  = aws_vpc.vpc_eks.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name                     = each.key
    "kubernetes.io/role/elb" = "1"
  }
}

# Create private subnets for internal access
resource "aws_subnet" "vpc_private_subnets" {
  for_each = var.aws_vpc_private_subnets

  vpc_id                  = aws_vpc.vpc_eks.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = {
    Name                     = each.key
    "karpenter.sh/discovery" = var.eks_cluster_name
  }
}

# Create internet gateway for public subnets
resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = aws_vpc.vpc_eks.id

  tags = {
    Name = var.eks_cluster_name
  }
}

# Create route table for public subnets
resource "aws_route_table" "vpc_public_route_table" {
  vpc_id = aws_vpc.vpc_eks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_igw.id
  }

  tags = {
    Name = var.eks_cluster_name
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "vpc_public_route_table_association" {
  for_each = aws_subnet.vpc_public_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.vpc_public_route_table.id
}

# Create one EIP for each NAT gateway in public subnets
resource "aws_eip" "vpc_nat_eip" {
  for_each = aws_subnet.vpc_public_subnets

  domain = "vpc"

  tags = {
    Name = "EIP-${each.key}"
  }
}

# Create NAT Gateways in public subnets
resource "aws_nat_gateway" "vpc_nat_gateway" {
  for_each = aws_subnet.vpc_public_subnets

  allocation_id = aws_eip.vpc_nat_eip[each.key].id
  subnet_id     = each.value.id

  tags = {
    Name = "NAT-${each.key}"
  }
}

# Create a mapping of availability zones to NAT Gateway IDs
locals {
  nat_gateways = {
    for key, natgw in aws_nat_gateway.vpc_nat_gateway :
    aws_subnet.vpc_public_subnets[key].availability_zone => natgw.id
  }
}

# Create route tables for private subnets and associate with NAT Gateways
resource "aws_route_table" "vpc_private_route_table" {
  for_each = aws_subnet.vpc_private_subnets

  vpc_id = aws_vpc.vpc_eks.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = local.nat_gateways[each.value.availability_zone]
  }

  tags = {
    Name = "PrivateRT-${each.key}"
  }
}

# Associate private subnets with their respective route tables
resource "aws_route_table_association" "vpc_private_route_table_association" {
  for_each = aws_subnet.vpc_private_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.vpc_private_route_table[each.key].id
}

locals {
  subnet_ids = concat(
    [for subnet in aws_subnet.vpc_private_subnets : subnet.id],
    [for subnet in aws_subnet.vpc_public_subnets : subnet.id]
  )

  subnets_private_ids = [for subnet in aws_subnet.vpc_private_subnets : subnet.id]
}
