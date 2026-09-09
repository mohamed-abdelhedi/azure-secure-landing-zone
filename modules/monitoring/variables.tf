variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}
variable "location" {
  description = "Location of the resource group"
  type        = string
}
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
variable "retention_in_days" {
  description = "Number of days to retain data in Log Analytics Workspace"
  type        = number
  default     = 30
}
variable "sku" {
  description = "SKU of the Log Analytics Workspace"
  type        = string
  default     = "PerGB2018"
}

variable "admin_email" {
  description = "Email address of the administrator to receive alerts"
  type        = string
}