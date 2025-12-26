output "hub_vnet_id" {
  description = "ID of the hub virtual network"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Name of the hub virtual network"
  value       = azurerm_virtual_network.hub.name
}

output "firewall_private_ip" {
  description = "Private IP address of Azure Firewall"
  value       = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

output "firewall_id" {
  description = "ID of the Azure Firewall"
  value       = azurerm_firewall.hub.id
}

output "vpn_gateway_id" {
  description = "ID of the VPN Gateway"
  value       = var.enable_vpn_gateway ? azurerm_virtual_network_gateway.vpn[0].id : null
}

output "bastion_host_id" {
  description = "ID of the Bastion Host"
  value       = var.enable_bastion ? azurerm_bastion_host.hub[0].id : null
}
