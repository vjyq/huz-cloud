provider "aws" {
  profile = "default"
  region = "${var.region_name}"
  version = "2.41.0"
}

resource "aws_vpc" "huz_vpc" {
  cidr_block = "${var.cidr}"
  tags = {
    Name = "huz_vpc"
  }
}

resource "aws_subnet" "huz_vpc_subnet_public" {
  availability_zone = "ap-northeast-1a"
  cidr_block = "${var.cidr_subnet_public}"
  tags = {
    Name = "huz_vpc_subnet_public"
  }
  vpc_id = "${aws_vpc.huz_vpc.id}"
}

resource "aws_internet_gateway" "huz_vpc_ig" {
  tags = {
    Name = "huz_vpc_ig"
  }
  vpc_id = "${aws_vpc.huz_vpc.id}"
}

resource "aws_route_table" "huz_vpc_subnet_route" {
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.huz_vpc_ig.id}"
  }
  tags = {
    Name = "huz_vpc_subnet_route"
  }
  vpc_id = "${aws_vpc.huz_vpc.id}"
}

resource "aws_route_table_association" "huz_vpc_subnet_route_public"{
  subnet_id = "${aws_subnet.huz_vpc_subnet_public.id}"
  route_table_id = "${aws_route_table.huz_vpc_subnet_route.id}"
}

resource "aws_security_group" "huz_sg" {
  name = "huz_sg"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "huz_sg"
  }
  vpc_id = "${aws_vpc.huz_vpc.id}"
}

resource "aws_instance" "huz_instance" {
  ami = "${var.ami_id}"
  associate_public_ip_address = true
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  user_data = "${file("bootstrap.sh")}"
  subnet_id = "${aws_subnet.huz_vpc_subnet_public.id}"
  tags = {
    Name = "huz_instance"
  }
  vpc_security_group_ids = ["${aws_security_group.huz_sg.id}"]
}

output "huz_instance_id" {
  value = "${aws_instance.huz_instance.id}"
}

output "huz_instance_public_ip" {
  value = "${aws_instance.huz_instance.public_ip}"
}
