# Resource Group for Dev Environment
resource "azurerm_resource_group" "dev" {
  name     = "rg-landingzone-dev-eastus"
  location = var.location
  
  tags = local.common_tags
}

# Hub Network Module
module "hub_network" {
  source = "../../modules/network-hub"
  
  resource_group_name    = azurerm_resource_group.dev.name
  location               = azurerm_resource_group.dev.location
  hub_vnet_name          = "vnet-hub-dev-eastus-001"
  hub_vnet_address_space = ["10.0.0.0/16"]
  
  firewall_subnet_prefix = "10.0.0.0/26"
  gateway_subnet_prefix  = "10.0.1.0/26"
  bastion_subnet_prefix  = "10.0.2.0/26"
  
  environment        = var.environment
  enable_vpn_gateway = false  # Disabled in dev to save costs
  enable_bastion     = true
  firewall_sku       = "Standard"  # Use Standard in dev (Premium is expensive)
  
  tags = local.common_tags
}

# App Spoke Network Module
module "app_spoke" {
  source = "../../modules/network-spoke"
  
  resource_group_name       = azurerm_resource_group.dev.name
  location                  = azurerm_resource_group.dev.location
  spoke_vnet_name           = "vnet-app-dev-eastus-001"
  spoke_vnet_address_space  = ["10.1.0.0/16"]
  
  hub_vnet_id        = module.hub_network.hub_vnet_id
  hub_vnet_name      = module.hub_network.hub_vnet_name
  firewall_private_ip = module.hub_network.firewall_private_ip
  
  subnets = {
    aks = {
      name             = "snet-aks-dev"
      address_prefixes = ["10.1.0.0/22"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
      delegations      = []
    }
    
    appgw = {
      name             = "snet-appgw-dev"
      address_prefixes = ["10.1.4.0/24"]
      service_endpoints = []
      delegations      = []
    }
  }
  
  environment = var.environment
  tags        = local.common_tags
  
  depends_on = [module.hub_network]
}

# Data Spoke Network Module
module "data_spoke" {
  source = "../../modules/network-spoke"
  
  resource_group_name       = azurerm_resource_group.dev.name
  location                  = azurerm_resource_group.dev.location
  spoke_vnet_name           = "vnet-data-dev-eastus-001"
  spoke_vnet_address_space  = ["10.2.0.0/16"]
  
  hub_vnet_id        = module.hub_network.hub_vnet_id
  hub_vnet_name      = module.hub_network.hub_vnet_name
  firewall_private_ip = module.hub_network.firewall_private_ip
  
  subnets = {
    data = {
      name             = "snet-data-dev"
      address_prefixes = ["10.2.0.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
      delegations      = []
    }
    
    privatelink = {
      name             = "snet-privatelink-dev"
      address_prefixes = ["10.2.1.0/24"]
      service_endpoints = []
      delegations      = []
    }
  }
  
  environment = var.environment
  tags        = local.common_tags
  
  depends_on = [module.hub_network]
}
