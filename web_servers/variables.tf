# ---------------------------------------------------------------------------------------------------------------------
# 1. GENERAL
# ---------------------------------------------------------------------------------------------------------------------

# 1.1 REQUIRED

variable "env" {
  description = "Environment (e.g. staging vs prod)"
  type        = string
}

variable "app_name" {
  description = "Name of application (e.g. todoist)"
  type        = string
}

variable "domain_name" {
  description = "Your domain name (e.g. example.com)"
  type        = string
}

variable "id_rsa_pub" {
  description = "Your public SSH key"
  type        = string
}

# 1.2 OPTIONAL

variable "app_region" {
  description = "Region for database"
  type        = string
  default     = "us-east-2"
}

# ---------------------------------------------------------------------------------------------------------------------
# 2. WEB SERVERS
# ---------------------------------------------------------------------------------------------------------------------

# 2.1 REQUIRED

variable "min_size" {
  description = "The minimum number of EC2 Instances in the ASG"
  type        = number
}

variable "max_size" {
  description = "The maximum number of EC2 Instances in the ASG"
  type        = number
}

variable "business_hours_size" {
  description = "Amount of default instances during business hours (9am - 9pm)"
  type        = number
}

variable "night_hours_size" {
  description = "Amount of default instances during night hours (9pm - 9am)"
  type        = number
}

# 2.2 OPTIONAL

variable "enable_autoscaling" {
  description = "Turn on / off autoscaling"
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g. t2.micro)"
  type        = string
  default     = "t2.micro"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 3000
}

variable "health_check_path" {
  description = "The path for the ASG health check"
  type        = string
  default     = "/health-check"
}

