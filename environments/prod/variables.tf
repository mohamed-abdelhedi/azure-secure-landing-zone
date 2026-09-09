variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "owner" {
  description = "Owner/Team responsible for resources"
  type        = string
  default     = "Platform Team"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "IT-Infrastructure"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "Landing Zone"
}

variable "admin_email" {
  description = "Administrator email address for operational and security alerts"
  type        = string
  default     = "secops@example.com"
}

locals {
  common_tags = {
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    Project     = var.project
    ManagedBy   = "Terraform"
    Repository  = "github.com/mohamed-abdelhedi/terraform"
  }
}
