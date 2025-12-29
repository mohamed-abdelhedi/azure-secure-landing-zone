variable "resource_group_name" {
  description = "Name of the resource group for spoke networking resources"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "spoke_vnet_name" {
  description = "Name of the spoke virtual network"
  type        = string
}

variable "spoke_vnet_address_space" {
  description = "Address space for the spoke VNet"
  type        = list(string)
}

variable "subnets" {
  description = "Map of subnets to create in the spoke VNet"
  type = map(object({
    name             = string
    address_prefixes = list(string)
    service_endpoints = list(string)
    delegations      = list(string)
  }))
  default = {}
}

variable "hub_vnet_id" {
  description = "ID of the hub virtual network for peering"
  type        = string
}

variable "hub_vnet_name" {
  description = "Name of the hub virtual network"
  type        = string
}

variable "firewall_private_ip" {
  description = "Private IP of Azure Firewall for routing"
  type        = string
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

variable "use_remote_gateways" {
  description = "Whether to use the hub's VPN gateway. Set to false if hub has no gateway."
  type        = bool
  default     = false
}
