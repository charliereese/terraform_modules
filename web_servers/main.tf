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
# 2. WEB SERVERS (LAUNCH CONFIGURATION + USER DATA)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_launch_configuration" "example" {
  image_id        = data.aws_ami.image.id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instance.id]

  key_name = aws_key_pair.ec2.key_name

  user_data = data.template_file.user_data.rendered

  # Required if using launch configuration with auto scaling group
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_ami" "image" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "tag:application"
    values = ["${var.app_name}-web-server"]
  }
}

data "template_file" "user_data" {
  template = file("${path.root}/user-data.sh")

  vars = {
    env              = var.env
    application_name = var.app_name
    db_address       = data.terraform_remote_state.db.outputs.address
    db_username      = data.terraform_remote_state.db.outputs.db_username
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = "${var.app_name}-terraform-state-storage"
    key    = "terraform/${var.env}-state/data"
    region = "us-east-2"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# 3. AUTOSCALING GROUP + SCHEDULES
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_autoscaling_group" "example" {
  # Depend on the launch configuration's name; 
  # each time it's replaced ASG is also replaced
  name = "${var.app_name}-${var.env}-${aws_launch_configuration.example.name}"

  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids
  target_group_arns    = [aws_lb_target_group.asg.arn]
  health_check_type    = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  # Wait for at least this many instances to pass health checks before
  # considering the ASG deployment complete
  min_elb_capacity = var.min_size

  # When replacing this ASG, create the replacement first, and only delete the
  # original after
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.app_name}-${var.env}"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name  = "${var.app_name}-${var.env}-scale-out-during-business-hours"
  min_size               = var.min_size
  max_size               = var.max_size
  desired_capacity       = var.business_hours_size
  recurrence             = "0 9 * * *"
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name  = "${var.app_name}-${var.env}-scale-in-at-night"
  min_size               = var.min_size
  max_size               = var.max_size
  desired_capacity       = var.night_hours_size
  recurrence             = "0 21 * * *"
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_lb_target_group" "asg" {
  name     = "${var.app_name}-${var.env}"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# 4. APPLICATION LOAD BALANCER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_lb" "example" {
  name               = "${var.app_name}-${var.env}"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.alb.id]
}

# 4.1 Listen for http

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = local.http_port
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "asg-http" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    field  = "path-pattern"
    values = ["*"]
  }

  action {
    type = "redirect"

    redirect {
      port        = local.https_port
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# 4.2 Listen for https

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.example.arn
  port              = local.https_port
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "asg-https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  condition {
    field  = "path-pattern"
    values = ["*"]
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# 5. VPCs + SUBNET IDs
# ---------------------------------------------------------------------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# ---------------------------------------------------------------------------------------------------------------------
# 6. SECURITY GROUPS
# ---------------------------------------------------------------------------------------------------------------------

# 6.1 Instance security groups

resource "aws_security_group" "instance" {
  name = "${var.app_name}-${var.env}-instance"
}

resource "aws_security_group_rule" "allow_server_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port   = var.server_port
  to_port     = var.server_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_server_ssh_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port   = local.ssh_port
  to_port     = local.ssh_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_server_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.instance.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

# 6.2 Application load balancer security groups

resource "aws_security_group" "alb" {
  name = "${var.app_name}-${var.env}-alb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_https_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.https_port
  to_port     = local.https_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

# ---------------------------------------------------------------------------------------------------------------------
# 7. CLOUDWATCH METRICS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name  = "${var.app_name}-${var.env}-high-cpu-utilization"
  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.example.name
  }

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Average"
  threshold           = 90
  unit                = "Percent"
}

# ---------------------------------------------------------------------------------------------------------------------
# 8. SSL CERT
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_acm_certificate" "cert" {
  count             = var.env == "prod" ? 0 : 1
  domain_name       = "*.${var.domain_name}"
  validation_method = "DNS"

  tags = {
    Environment = var.env
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = var.env == "prod" ? data.aws_acm_certificate.cert.arn : aws_acm_certificate.cert[0].arn
}

data "aws_acm_certificate" "cert" {
  domain      = "*.${var.domain_name}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

# ---------------------------------------------------------------------------------------------------------------------
# 9. LOCAL VARIABLES + SSH
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_key_pair" "ec2" {
  key_name   = "ssh-key-${var.app_name}-${var.env}"
  public_key = var.id_rsa_pub
}

locals {
  ssh_port     = 22
  http_port    = 80
  https_port   = 443
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}
