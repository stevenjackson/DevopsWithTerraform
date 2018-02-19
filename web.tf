data "aws_ami" "web" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "default" {
  key_name = "default"
  public_key ="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRxRFcQsFixPXirNrLLHG3wA2yzNHUAW/NmQc/nz6IWgAKM09wAVfNLgvfNZskPMQoiiz4R0+iVjJd93SQr5cbJb3fJ+wtSWpy032fxitAHLS75PsaGZ1X5Q/NxzzPRSDbncndR3kIO8XFB8igZi8bbL6xNxNywZ5zvrx0ZjYC6obv6ho2mbd6ROCDeiwH1m9Y8eOYs1NKkoQhhm2joMuShyUqGfNrP8nKFPpStGaBZg+IyLXRIykzgU7eg4tKutI9TyIXK52ecLB33Y0lvo35LJVNrI4CyR4tYwTu127e3CjX93G6euIItWAIdbItTeYc3BJ97Afoly2XMOupSHXN steve@testdouble.com"
}

##################
# Provisioned

resource "aws_instance" "web" {
  ami           = "${data.aws_ami.web.id}"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.public.id}"
  key_name = "${aws_key_pair.default.key_name}"
  associate_public_ip_address = true
  vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]

  tags {
    Name = "WebServer"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
    ]

    connection {
      type     = "ssh"
      user     = "ubuntu"
    }
  }
}
