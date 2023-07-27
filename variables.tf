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