# Resource Group for Production Environment
resource "azurerm_resource_group" "prod" {
  name     = "rg-landingzone-prod-eastus"
  location = var.location

  tags = local.common_tags
}

# Hub Network Module - Production Grade
module "hub_network" {
  source = "../../modules/network-hub"

  resource_group_name    = azurerm_resource_group.prod.name
  location               = azurerm_resource_group.prod.location
  hub_vnet_name          = "vnet-hub-prod-eastus-001"
  hub_vnet_address_space = ["10.0.0.0/16"]

  firewall_subnet_prefix = "10.0.0.0/26"
  gateway_subnet_prefix  = "10.0.1.0/26"
  bastion_subnet_prefix  = "10.0.2.0/26"

  environment        = var.environment
  enable_vpn_gateway = true      # Enabled for hybrid enterprise connectivity
  enable_bastion     = true
  firewall_sku       = "Premium" # Premium SKU for IDPS & TLS inspection

  tags = local.common_tags
}

# App Spoke Network Module
module "app_spoke" {
  source = "../../modules/network-spoke"

  resource_group_name      = azurerm_resource_group.prod.name
  location                 = azurerm_resource_group.prod.location
  spoke_vnet_name          = "vnet-app-prod-eastus-001"
  spoke_vnet_address_space = ["10.1.0.0/16"]

  hub_vnet_id         = module.hub_network.hub_vnet_id
  hub_vnet_name       = module.hub_network.hub_vnet_name
  firewall_private_ip = module.hub_network.firewall_private_ip

  subnets = {
    aks = {
      name              = "snet-aks-prod"
      address_prefixes  = ["10.1.0.0/22"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
      delegations       = []
    }

    appgw = {
      name              = "snet-appgw-prod"
      address_prefixes  = ["10.1.4.0/24"]
      service_endpoints = []
      delegations       = []
    }
  }

  environment         = var.environment
  tags                = local.common_tags
  use_remote_gateways = true # Route hybrid traffic through Hub VPN Gateway

  depends_on = [module.hub_network]
}

# Data Spoke Network Module
module "data_spoke" {
  source = "../../modules/network-spoke"

  resource_group_name      = azurerm_resource_group.prod.name
  location                 = azurerm_resource_group.prod.location
  spoke_vnet_name          = "vnet-data-prod-eastus-001"
  spoke_vnet_address_space = ["10.2.0.0/16"]

  hub_vnet_id         = module.hub_network.hub_vnet_id
  hub_vnet_name       = module.hub_network.hub_vnet_name
  firewall_private_ip = module.hub_network.firewall_private_ip

  subnets = {
    data = {
      name              = "snet-data-prod"
      address_prefixes  = ["10.2.0.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
      delegations       = []
    }

    privatelink = {
      name              = "snet-privatelink-prod"
      address_prefixes  = ["10.2.1.0/24"]
      service_endpoints = []
      delegations       = []
    }
  }

  environment         = var.environment
  tags                = local.common_tags
  use_remote_gateways = true # Route hybrid traffic through Hub VPN Gateway

  depends_on = [module.hub_network]
}

# Central Monitoring & SIEM/SOAR Module
module "monitoring" {
  source = "../../modules/monitoring"

  resource_group_name = azurerm_resource_group.prod.name
  location            = azurerm_resource_group.prod.location
  environment         = var.environment
  retention_in_days   = 90 # Extended audit retention for production
  sku                 = "PerGB2018"
  admin_email         = var.admin_email
  tags                = local.common_tags

  depends_on = [azurerm_resource_group.prod]
}
