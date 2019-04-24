variable "OPAL_ENV" {
  description = "The env this config will deploy to. Should be defined in the environment variable TF_VAR_OPAL_ENV."
  default     = "internal"
}
variable "OPAL_AMI" {
  description = "The AMI used by the instance. Should be defined in the environment variable TF_VAR_OPAL_AMI."
  default     = "ami-a042f4d8" #Centos 7 in us-west-2
}
variable "AWS_REGION" {
  description = "The region to deploy to."
  default     = "us-west-2"
}

variable "access_key" {
  default = ""
}

variable "secret_key" {
  default = ""
}

provider "aws" {
  region     = "${var.AWS_REGION}"
  profile    = "default"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.OPAL_ENV}"
  }
}

resource "aws_eip" "main-eip" {
  instance = "${aws_instance.ec2-instance-001.id}"
  vpc      = true
}

resource "aws_internet_gateway" "main-gw" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route_table" "main-route-table" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main-gw.id}"
  }
}

resource "aws_route_table_association" "route-table-subnet-association" {
  subnet_id      = "${aws_subnet.main-subnet.id}"
  route_table_id = "${aws_route_table.main-route-table.id}"
}

resource "aws_subnet" "main-subnet" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "${aws_vpc.main.cidr_block}"
}

resource "aws_security_group" "allow-ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_instance" "ec2-instance-001" {
  ami             = "${var.OPAL_AMI}"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.allow_ssh.id}"]
  subnet_id       = "${aws_subnet.main.id}"
  tags = {
    Name = "${var.OPAL_ENV}"
  }
}

output "ec2-instance-001-tag-Name" {
  value = "${aws_instance.ec2-instance-001.tags["Name"]}"
}

output "ec2-instance-001-public-ip" {
  value = "${aws_instance.ec2-instance-001.public_ip}"
}

output "public-subnet-id" {
  value = "${aws_subnet.main-subnet.id}"
}
