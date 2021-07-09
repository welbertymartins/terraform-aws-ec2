# define the provider
provider "aws" {
  region = "us-east-1"
}

# sets the aws instance's security group
resource "aws_security_group" "web-sg" {
  name = "web-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

# sets the image in use to the latest ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# define the instance
resource "aws_instance" "web" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3.nano"
  vpc_security_group_ids = [aws_security_group.web-sg.id]

  provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"
  }

  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/tmp/docker-compose.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/script.sh",
      "sudo /tmp/script.sh args",
      "sudo docker-compose -f /tmp/docker-compose.yml up",
      "sudo ufw allow 5432/tcp"
    ]
  }

  # connect the instance
  key_name = "private_key_default"
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("private_key_default.pem")
    timeout = "2m"
    host = self.public_ip
  }
}