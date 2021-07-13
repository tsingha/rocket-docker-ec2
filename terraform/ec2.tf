provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

resource "aws_key_pair" "linux" {
  key_name   = "linux"
  public_key = file("key.pub")
}

resource "aws_security_group" "linux" {
  name        = "linux-security-group"
  description = "Allow HTTP, HTTPS and SSH traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "linux-sg"
  }
}


resource "aws_instance" "linux" {
  key_name      = aws_key_pair.linux.key_name
  ami           = "ami-0ba62214afa52bec7"
  instance_type = "t3.medium"

  tags = {
    Name = "Linux-Docker"
  }

  vpc_security_group_ids = [
    aws_security_group.linux.id
  ]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("key")
    host        = self.public_ip
  }

}

resource "aws_eip" "linux" {
  vpc      = true
  instance = aws_instance.linux.id
}
