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

# 1.2 OPTIONAL

variable "db_region" {
  description = "Region for database"
  type        = string
  default     = "us-east-2"
}

# ---------------------------------------------------------------------------------------------------------------------
# 2. DB RELATED
# ---------------------------------------------------------------------------------------------------------------------

# 2.1 REQUIRED

variable "db_password" {
  description = "The password for the database"
  type        = string
}

variable "db_username" {
  description = "The username for the database"
  type        = string
}

variable "db_encrypted" {
  description = "Should DB instance be encrypted (true / false)?"
  type        = bool
}

variable "db_instance_class" {
  description = "DB instance class (e.g. db.t2.micro, free tier / db.t3.micro, if encrypted / db.t3.small)"
  type        = string
}

# 2.2 OPTIONAL

variable "db_engine" {
  description = "DB engine (e.g. mysql, etc)"
  type        = string
  default     = "postgres"
}

variable "allocated_storage" {
  description = "Allocated storage (GB) for DB"
  type        = number
  default     = 10
}

variable "max_allocated_storage" {
  description = "Max allocated storage (GB) for DB (if instance class supports autoscaling)"
  type        = number
  default     = 100
}

variable "skip_final_snapshot" {
  description = "Should DB skip snapshot before deletion?"
  type        = bool
  default     = true
}
