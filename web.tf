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
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSwnJXN+ZFT/GkywoLNO6kkWIf75Y9zARLM+J04V4+m3r0L1pVqNF47jCRRV1lAHB6sGr08o6BDZBO0IsO3g5gcekIq8zjZCsFDAQEmTlPamOXc60PPRoKQhoHLz64lExdWpkVhIUKbCGjtoC2OaomQJx2Wxg5F9A/vz+gLkCamYjUTXm9MtUPdcv02/3CNynuCAicnzei4YvburuWAJ2md9PbYm29PrArqu7uhu70a79jS8MxpAWV7HIVeFQyAQylQamGa8TMc+jETi7tn3zwrcDPAP4ZXX/fr9l6AjfVpKkGeoYhukVG2KdVB4gQDHRWluH0qoqFXQFrIR5F1poT"
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
    script = "provision_web.sh"

    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = "${file("/Users/dusty/.ssh/kcdc.pem")}"
    }
  }
}

##################
# Packer built AMI

# resource "aws_instance" "web" {
#   ami           = "ami-e8dafa93"
#   instance_type = "t2.micro"
#   subnet_id     = "${aws_subnet.public.id}"
#   key_name = "${aws_key_pair.default.key_name}"
#   associate_public_ip_address = true
#   vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]

#   tags {
#     Name = "WebServer"
#   }
# }

resource "aws_elb" "web" {
  name = "public-web-2"
  subnets = ["${aws_subnet.public.id}"]
  security_groups = ["${aws_security_group.allow_all.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = ["${aws_instance.web.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "web"
  }
}

###################
# ASG
#
# resource "aws_autoscaling_group" "asg_web" {
#   lifecycle { create_before_destroy = true }

#   # spread the app instances across the availability zones
#   vpc_zone_identifier = ["${aws_subnet.public.id}"]

#   # interpolate the LC into the ASG name so it always forces an update
#   name = "asg-web - ${aws_launch_configuration.lc_web.name}"
#   max_size = 5
#   min_size = 2
#   wait_for_elb_capacity = 2
#   desired_capacity = 2
#   health_check_grace_period = 300
#   health_check_type = "ELB"
#   launch_configuration = "${aws_launch_configuration.lc_web.id}"
#   load_balancers = ["${aws_elb.web.id}"]
# }

# resource "aws_launch_configuration" "lc_web" {
#     lifecycle { create_before_destroy = true }

#     # image_id = "ami-e8dafa93" # App version 1!
#     image_id = "ami-f3b49488" # App version 2!
#     instance_type = "t2.micro"

#     # Our Security group to allow HTTP and SSH access
#     security_groups = ["${aws_security_group.allow_all.id}"]
# }

# resource "aws_elb" "web" {
#   name = "public-web-2"
#   subnets = ["${aws_subnet.public.id}"]
#   security_groups = ["${aws_security_group.allow_all.id}"]

#   listener {
#     instance_port     = 80
#     instance_protocol = "http"
#     lb_port           = 80
#     lb_protocol       = "http"
#   }

#   health_check {
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     timeout             = 3
#     target              = "HTTP:80/"
#     interval            = 30
#   }

#   cross_zone_load_balancing   = true
#   idle_timeout                = 400
#   connection_draining         = true
#   connection_draining_timeout = 400

#   tags {
#     Name = "web"
#   }
# }
#################
