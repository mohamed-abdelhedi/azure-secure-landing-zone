# Spoke Virtual Network
resource "azurerm_virtual_network" "spoke" {
  name                = var.spoke_vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.spoke_vnet_address_space

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Purpose"     = "Spoke Network"
    }
  )
}

# Subnets in Spoke VNet
resource "azurerm_subnet" "spoke" {
  for_each = var.subnets

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints

  # Dynamic delegation block
  dynamic "delegation" {
    for_each = each.value.delegations
    content {
      name = "delegation-${delegation.value}"
      service_delegation {
        name = delegation.value
      }
    }
  }
}

# Network Security Group for each subnet
resource "azurerm_network_security_group" "spoke" {
  for_each = var.subnets

  name                = "nsg-${each.value.name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(var.tags, { "Subnet" = each.value.name })
}

# Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "spoke" {
  for_each = var.subnets

  subnet_id                 = azurerm_subnet.spoke[each.key].id
  network_security_group_id = azurerm_network_security_group.spoke[each.key].id
}

# Route Table - Force all traffic through Azure Firewall
resource "azurerm_route_table" "spoke" {
  name                = "rt-${var.spoke_vnet_name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  route {
    name                   = "to-internet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip
  }

  tags = merge(var.tags, { "Purpose" = "Force Tunnel" })
}

# Associate Route Table with Subnets
resource "azurerm_subnet_route_table_association" "spoke" {
  for_each = var.subnets

  subnet_id      = azurerm_subnet.spoke[each.key].id
  route_table_id = azurerm_route_table.spoke.id
}

# VNet Peering: Spoke to Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-${var.spoke_vnet_name}-to-hub"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = var.hub_vnet_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = true  # Use hub's VPN gateway
}

# VNet Peering: Hub to Spoke (requires hub resource group)
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-${var.spoke_vnet_name}"
  resource_group_name       = var.resource_group_name  # Assumes same RG
  virtual_network_name      = var.hub_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  use_remote_gateways       = false
}
