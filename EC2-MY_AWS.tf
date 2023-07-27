#EC2-My_AWS.tf

provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"  # Ścieżka do katalogu z modułem VPC

  # Parametry modułu VPC
  vpc_cidr_block       = var.vpc_cidr_block
  private_subnet_count = var.private_subnet_count
  public_subnet_count  = var.public_subnet_count
}

# variables.tf

variable "region" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "private_subnet_count" {
  type = number
}

variable "public_subnet_count" {
  type = number
}
# modules/vpc/EC2-My_AWS.tf

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "MainVPC"
  }
}

resource "aws_subnet" "private" {
  count             = var.private_subnet_count
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, count.index)
  vpc_id            = aws_vpc.main.id
  availability_zone = "us-east-1a"  # Dostosuj do swojego regionu
}

resource "aws_subnet" "public" {
  count             = var.public_subnet_count
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, 100 + count.index)
  vpc_id            = aws_vpc.main.id
  availability_zone = "us-east-1a"  # Dostosuj do swojego regionu
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_nat_gateway" "nat" {
  count = var.public_subnet_count

  subnet_id      = aws_subnet.public[count.index].id
  allocation_id = aws_eip.nat[count.index].id
}

resource "aws_eip" "nat" {
  count = var.public_subnet_count
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "PrivateRouteTable"
  }
}

resource "aws_route_table_association" "private" {
  count          = var.private_subnet_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table_association" "public" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}
