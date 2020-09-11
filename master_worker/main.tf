# Master worker is for running cron jobs 
# and processing enqueued rails jobs

# ---------------------------------------------------------------------------------------------------------------------
# 1. GENERAL
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = var.app_region

  # Allow any 2.x version of the AWS provider
  version = "~> 2.0"
}

# ---------------------------------------------------------------------------------------------------------------------
# 2. MASTER WORKER (RUNS CRON + JOBS)
# ---------------------------------------------------------------------------------------------------------------------

# Web server AMI
# Note: master worker uses same AMI as web server for simplicity
data "aws_ami" "image" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:application"
    values = ["${var.app_name}-web-server"]
  }
}

# Master worker server
resource "aws_instance" "master_worker" {
  ami           = data.aws_ami.image.id
  instance_type = var.instance_type

  key_name  = aws_key_pair.ec2.key_name
  user_data = data.template_file.user_data.rendered

  vpc_security_group_ids = [aws_security_group.master_worker.id]

  tags = {
    Name = "${var.app_name}-master-worker-${var.env}"
  }
}

# Need user data script for master worker on boot
data "template_file" "user_data" {
  template = file("${path.root}/user-data.sh")

  vars = {
    env              = var.env
    application_name = var.app_name
    db_address       = data.terraform_remote_state.db.outputs.address
    db_username      = data.terraform_remote_state.db.outputs.db_username
  }
}

# Pull DB info from remote state
data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = "${var.app_name}-terraform-state-storage"
    key    = "terraform/${var.env}-state/data"
    region = "us-east-2"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# 3. SECURITY GROUPS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "master_worker" {
  name = "${var.app_name}-${var.env}-master-worker"
}

resource "aws_security_group_rule" "allow_server_ssh_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.master_worker.id

  from_port   = local.ssh_port
  to_port     = local.ssh_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_server_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.master_worker.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

# ---------------------------------------------------------------------------------------------------------------------
# 4. LOCAL VARIABLES + SSH
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_key_pair" "ec2" {
  key_name   = "ssh-key-${var.app_name}-${var.env}-master-worker"
  public_key = var.id_rsa_pub
}

locals {
  ssh_port     = 22
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}
