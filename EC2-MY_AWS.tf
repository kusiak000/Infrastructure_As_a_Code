variable "vpc_cidr_block" {
  description = "CIDR bloku VPC"
}

variable "private_subnet_cidr_blocks" {
  type        = list(string)
  description = "Lista CIDR bloków dla podsieci prywatnych"
}

variable "public_subnet_cidr_blocks" {
  type        = list(string)
  description = "Lista CIDR bloków dla podsieci publicznych"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr_block
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidr_blocks)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = "us-east-1a"  # Zmień to na odpowiednią strefę dostępności
}

resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidr_blocks)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.public_subnet_cidr_blocks[count.index]
  availability_zone = "us-east-1a"  # Zmień to na odpowiednią strefę dostępności
}

resource "aws_eip" "nat_gateway_eip" {
  count = length(var.public_subnet_cidr_blocks)
}

resource "aws_nat_gateway" "nat_gateway" {
  count          = length(var.public_subnet_cidr_blocks)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  allocation_id  = aws_eip.nat_gateway_eip[count.index].id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  dynamic "route" {
    for_each = aws_subnet.private_subnets
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat_gateway[0].id
      subnet_id      = route.value.id
    }
  }
}
variable "subnet_id" {
  description = "ID podsieci, w której ma zostać utworzona instancja EC2"
}

variable "instance_type" {
  description = "Typ instancji EC2 (np. t2.micro)"
}

variable "ami_id" {

  description = "ID obrazu maszyny (AMI) - AMI WinX64 ami-07fg6c5gt52891jy0 lub AMI Amazon Linux ami-04823729c75214919"
}

resource "aws_key_pair" "ssh_key_pair" {
  key_name   = "AWSKEY.pem"  # Zmień nazwę klucza SSH na swoją
  public_key = file("~/.ssh/AWSKEY.pem")  # Ścieżka do klucza publicznego SSH
}

resource "aws_security_group" "ec2_security_group" {
  name_prefix = "ec2-sg-"

  dynamic "ingress" {
    for_each = var.ami_id == "windows" ? [3389] : [22]  # Jeśli to Windows, otwórz port 3389, w przeciwnym razie otwórz port 22
    content {
      from_port = ingress.value
      to_port   = ingress.value
      protocol  = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

resource "aws_instance" "ec2_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = AWSKEY.pem

  vpc_security_group_ids = [
    aws_security_group.ec2_security_group.id,
  ]
}

output "ec2_instance_id" {
  value = aws_instance.ec2_instance.id
}

resource "aws_route_table_association" "private_subnet_association" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

output "vpc_id" {
  value = aws_vpc.my_vpc.id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnets[*].id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}
module "vpc_subnet_nat" {
  source = "./vpc_subnet_nat"

  vpc_cidr_block            = "10.200.0.0/16"
  private_subnet_cidr_blocks = ["10.200.1.0/24", "10.200.2.0/24"]
  public_subnet_cidr_blocks  = ["10.200.101.0/24", "10.200.102.0/24"]
}

module "ec2_instance" {
  source = "./ec2_instance"

  subnet_id     = module.vpc_subnet_nat.public_subnet_ids[0]  # Wybierz odpowiednią podsieć publiczną
  instance_type = "t2.micro"
  ami_id        = "linux"  # lub "windows" w zależności od typu maszyny
