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
# 2. MASTER WORKER (RUNS CRON + JOBS)
# ---------------------------------------------------------------------------------------------------------------------

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g. t2.micro)"
  type        = string
  default     = "t2.micro"
}
