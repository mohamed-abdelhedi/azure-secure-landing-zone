# Hub Virtual Network
resource "azurerm_virtual_network" "hub" {
  name                = var.hub_vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.hub_vnet_address_space

  tags = merge(
    var.tags,
    {
      "Environment" = var.environment
      "Purpose"     = "Hub Network"
    }
  )
}

# Azure Firewall Subnet (must be named exactly "AzureFirewallSubnet")
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.firewall_subnet_prefix]
}

# Gateway Subnet (must be named exactly "GatewaySubnet")
resource "azurerm_subnet" "gateway" {
  count                = var.enable_vpn_gateway ? 1 : 0
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.gateway_subnet_prefix]
}

# Azure Bastion Subnet (must be named exactly "AzureBastionSubnet")
resource "azurerm_subnet" "bastion" {
  count                = var.enable_bastion ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.bastion_subnet_prefix]
}

# Public IP for Azure Firewall
resource "azurerm_public_ip" "firewall" {
  name                = "pip-${var.hub_vnet_name}-fw"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(var.tags, { "Purpose" = "Firewall" })
}

# Azure Firewall Premium (with IDPS)
resource "azurerm_firewall" "hub" {
  name                = "afw-${var.environment}-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku
  firewall_policy_id  = azurerm_firewall_policy.hub.id

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  tags = merge(var.tags, { "Purpose" = "Network Security" })
}

# Firewall Policy with IDPS (Premium only)
resource "azurerm_firewall_policy" "hub" {
  name                = "afwp-${var.environment}-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.firewall_sku

  # Enable IDPS for Premium SKU
  dynamic "intrusion_detection" {
    for_each = var.firewall_sku == "Premium" ? [1] : []
    content {
      mode = "Alert"
    }
  }

  # Enable TLS Inspection for Premium SKU
  dynamic "tls_certificate" {
    for_each = var.firewall_sku == "Premium" ? [] : []
    content {
      key_vault_secret_id = ""  # Add Key Vault certificate ID here
      name                = "tls-inspection"
    }
  }

  dns {
    proxy_enabled = true
  }

  tags = merge(var.tags, { "Purpose" = "Firewall Policy" })
}

# Default Network Rule Collection - Allow DNS and NTP
resource "azurerm_firewall_policy_rule_collection_group" "network_rules" {
  name               = "DefaultNetworkRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 100

  network_rule_collection {
    name     = "AllowOutbound"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "AllowDNS"
      protocols             = ["UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["53"]
    }

    rule {
      name                  = "AllowNTP"
      protocols             = ["UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }
  }
}

# Application Rule Collection - Allow Azure and Microsoft endpoints
resource "azurerm_firewall_policy_rule_collection_group" "application_rules" {
  name               = "DefaultApplicationRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 200

  application_rule_collection {
    name     = "AllowAzure"
    priority = 200
    action   = "Allow"

    rule {
      name = "AllowWindowsUpdate"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["*"]
      destination_fqdns = [
        "*.windowsupdate.microsoft.com",
        "*.update.microsoft.com",
        "*.windowsupdate.com"
      ]
    }

    rule {
      name = "AllowAzureMonitor"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["*"]
      destination_fqdns = [
        "*.ods.opinsights.azure.com",
        "*.oms.opinsights.azure.com",
        "*.monitoring.azure.com"
      ]
    }
  }
}

# Public IP for VPN Gateway
resource "azurerm_public_ip" "vpn_gateway" {
  count               = var.enable_vpn_gateway ? 1 : 0
  name                = "pip-${var.hub_vnet_name}-vpn"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(var.tags, { "Purpose" = "VPN Gateway" })
}

# VPN Gateway with BGP enabled
resource "azurerm_virtual_network_gateway" "vpn" {
  count               = var.enable_vpn_gateway ? 1 : 0
  name                = "vgw-${var.environment}-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = var.environment == "prod" ? "VpnGw2" : "VpnGw1"
  enable_bgp          = true

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway[0].id
  }

  bgp_settings {
    asn = 65515
  }

  tags = merge(var.tags, { "Purpose" = "Hybrid Connectivity" })
}

# Public IP for Azure Bastion
resource "azurerm_public_ip" "bastion" {
  count               = var.enable_bastion ? 1 : 0
  name                = "pip-${var.hub_vnet_name}-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(var.tags, { "Purpose" = "Bastion" })
}

# Azure Bastion
resource "azurerm_bastion_host" "hub" {
  count               = var.enable_bastion ? 1 : 0
  name                = "bas-${var.environment}-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }

  tags = merge(var.tags, { "Purpose" = "Secure Access" })
}
