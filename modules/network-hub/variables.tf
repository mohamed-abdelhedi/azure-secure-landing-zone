variable "resource_group_name" {
  description = "Name of the resource group for hub networking resources"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "hub_vnet_name" {
  description = "Name of the hub virtual network"
  type        = string
}

variable "hub_vnet_address_space" {
  description = "Address space for the hub VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "firewall_subnet_prefix" {
  description = "Address prefix for Azure Firewall subnet"
  type        = string
  default     = "10.0.0.0/26"
}

variable "gateway_subnet_prefix" {
  description = "Address prefix for Gateway subnet"
  type        = string
  default     = "10.0.1.0/26"
}

variable "bastion_subnet_prefix" {
  description = "Address prefix for Bastion subnet"
  type        = string
  default     = "10.0.2.0/26"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_vpn_gateway" {
  description = "Whether to deploy VPN Gateway"
  type        = bool
  default     = true
}

variable "enable_bastion" {
  description = "Whether to deploy Azure Bastion"
  type        = bool
  default     = true
}

variable "firewall_sku" {
  description = "Azure Firewall SKU (Standard or Premium)"
  type        = string
  default     = "Premium"
  
  validation {
    condition     = contains(["Standard", "Premium"], var.firewall_sku)
    error_message = "Firewall SKU must be Standard or Premium."
  }
}
