variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
  validation {
    condition     = contains(["eastus", "eastus2", "westus2", "centralus"], var.location)
    error_message = "Choose an approved US region."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
  validation {
    condition     = var.environment == "dev"
    error_message = "This root module is only for dev."
  }
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
  default     = "admin@example.com"
}

locals {
  common_tags = {
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    Project     = var.project
    ManagedBy   = "Terraform"
    Repository  = "github.com/mohamed-abdelhedi/azure-secure-landing-zone"
  }
}
