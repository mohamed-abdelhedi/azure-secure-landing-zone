# Required service traffic from Microsoft's Azure Bastion NSG guidance.
# https://learn.microsoft.com/azure/bastion/bastion-nsg
locals {
  bastion_rules = {
    https_in       = { priority = 100, direction = "Inbound", source = "Internet", destination = "*", ports = ["443"], protocol = "Tcp" }
    gateway_in     = { priority = 110, direction = "Inbound", source = "GatewayManager", destination = "*", ports = ["443"], protocol = "Tcp" }
    balancer_in    = { priority = 120, direction = "Inbound", source = "AzureLoadBalancer", destination = "*", ports = ["443"], protocol = "Tcp" }
    bastion_in     = { priority = 130, direction = "Inbound", source = "VirtualNetwork", destination = "VirtualNetwork", ports = ["8080", "5701"], protocol = "*" }
    ssh_rdp_out    = { priority = 100, direction = "Outbound", source = "*", destination = "VirtualNetwork", ports = ["22", "3389"], protocol = "*" }
    cloud_out      = { priority = 110, direction = "Outbound", source = "*", destination = "AzureCloud", ports = ["443"], protocol = "Tcp" }
    bastion_out    = { priority = 120, direction = "Outbound", source = "VirtualNetwork", destination = "VirtualNetwork", ports = ["8080", "5701"], protocol = "*" }
    validation_out = { priority = 130, direction = "Outbound", source = "*", destination = "Internet", ports = ["80"], protocol = "*" }
  }
}

resource "azurerm_network_security_group" "bastion" {
  count               = var.enable_bastion ? 1 : 0
  name                = "nsg-bastion-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  dynamic "security_rule" {
    for_each = local.bastion_rules
    content {
      name                       = security_rule.key
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = "Allow"
      protocol                   = security_rule.value.protocol
      source_port_range          = "*"
      destination_port_ranges    = security_rule.value.ports
      source_address_prefix      = security_rule.value.source
      destination_address_prefix = security_rule.value.destination
    }
  }

  security_rule {
    name                       = "DenyOtherInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyOtherOutbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  count                     = var.enable_bastion ? 1 : 0
  subnet_id                 = azurerm_subnet.bastion[count.index].id
  network_security_group_id = azurerm_network_security_group.bastion[count.index].id
}
