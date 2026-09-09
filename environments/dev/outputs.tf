output "hub_vnet_id" {
  description = "ID of the hub virtual network"
  value       = module.hub_network.hub_vnet_id
}

output "app_spoke_vnet_id" {
  description = "ID of the app spoke virtual network"
  value       = module.app_spoke.spoke_vnet_id
}

output "data_spoke_vnet_id" {
  description = "ID of the data spoke virtual network"
  value       = module.data_spoke.spoke_vnet_id
}

output "firewall_private_ip" {
  description = "Private IP of Azure Firewall"
  value       = module.hub_network.firewall_private_ip
}

output "bastion_host_id" {
  description = "ID of the Bastion Host"
  value       = module.hub_network.bastion_host_id
}

output "log_analytics_workspace_id" {
  description = "ID of the Central Log Analytics Workspace"
  value       = module.monitoring.workspace_id
}

output "sentinel_onboarding_id" {
  description = "ID of the Microsoft Sentinel Onboarding"
  value       = module.monitoring.sentinel_onboarding_id
}
