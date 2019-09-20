# ---------------------------------------------------------------------------------------------------------------------
# 1. GENERAL
# ---------------------------------------------------------------------------------------------------------------------

# 1.1 REQUIRED

variable "app_name" {
  description = "Name of application"
  type        = string
}

# 1.2 OPTIONAL

variable "region" {
  description = "Region for database"
  type        = string
  default     = "us-east-2"
}
