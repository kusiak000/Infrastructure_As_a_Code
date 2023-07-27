# EC2-My_AWS.tf

provider "aws" {
  region = var.region
}

module "ec2_instance" {
  source = "./modules/ec2_instance"  # Ścieżka do katalogu z modułem EC2

  # Parametry modułu EC2
  vpc_id         = module.vpc.vpc_id
  subnet_id      = var.subnet_id
  ami            = var.ami
  key_name       = var.key_name
  instance_type  = var.instance_type
  is_windows     = var.is_windows
}

# variables.tf

variable "region" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "ami" {
  type = string
}

variable "key_name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "is_windows" {
  type = bool
}
# modules/ec2_instance/EC2-My_AWS.tf

resource "aws_instance" "ec2" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [aws_security_group.windows_rdp.id]

  key_name               = var.AWSKEY.pem
  associate_public_ip_address = true

  tags = {
    Name = "EC2Instance"
  }

  # Jeśli maszyna to Windows, dodaj odpowiedni użytkownik w zależności od dostawcy
  connection {
    type        = "ssh"
    user        = var.is_windows ? "Administrator" : "ec2-user"
    private_key = var.is_windows ? tls_private_key.private_key_pem : file("~/.ssh/id_rsa")
    host        = self.public_ip
  }
}

resource "tls_private_key" "private_key_pem" {
  algorithm = "RSA"
}

resource "aws_security_group" "windows_rdp" {
  name_prefix = "WindowsRDP"
  description = "Allow RDP Access for Windows EC2 Instance"

  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
