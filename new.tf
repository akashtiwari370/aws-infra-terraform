provider "aws" {
  region     = "ap-south-1"
  profile = "yourprofile"
}

resource "aws_key_pair" "deploy" {
  key_name   = "Terrakey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
} 


resource "aws_security_group" "terrasg" {
  name        = "terrasg"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-a7c3decf"

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terrasg"
  }
}


resource "aws_instance" "terraos" {
  ami           = "ami-005956c5f0f757d37"
  instance_type = "t2.micro"
  key_name  =  "Terrakey"
  security_groups = ["terrasg"]
  tags = {
    Name = "terraos"
  }
}



