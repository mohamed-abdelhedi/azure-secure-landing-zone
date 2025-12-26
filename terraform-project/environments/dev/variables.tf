variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
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

locals {
  common_tags = {
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    Project     = var.project
    ManagedBy   = "Terraform"
    Repository  = "github.com/yourorg/azure-landing-zone"
  }
}
