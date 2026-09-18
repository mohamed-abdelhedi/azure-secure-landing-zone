mock_provider "azurerm" {}

variables {
  resource_group_name = "rg-test"
  hub_vnet_name       = "vnet-test"
  environment         = "prod"
  location            = "eastus"
  tags                = { Environment = "prod", Owner = "Test", CostCenter = "Test", Project = "Test" }
}

run "premium_security" {
  command = plan
  assert {
    condition     = one(azurerm_firewall_policy.hub.intrusion_detection).mode == "Deny"
    error_message = "Premium IDPS must block detected threats."
  }
  assert {
    condition     = azurerm_firewall_policy.hub.threat_intelligence_mode == "Deny"
    error_message = "Threat intelligence must deny malicious traffic."
  }
  assert {
    condition     = length(azurerm_subnet_network_security_group_association.bastion) == 1
    error_message = "Bastion requires its NSG association."
  }
  assert {
    condition     = length(azurerm_network_security_group.bastion[0].security_rule) == 10
    error_message = "Bastion needs eight service rules and two deny rules."
  }
  assert {
    condition     = length(azurerm_firewall_policy.hub.tls_certificate) == 0
    error_message = "TLS inspection must not claim an unconfigured certificate."
  }
}

run "standard_without_optional_services" {
  command = plan
  variables {
    environment        = "dev"
    firewall_sku       = "Standard"
    enable_bastion     = false
    enable_vpn_gateway = false
  }
  assert {
    condition     = length(azurerm_firewall_policy.hub.intrusion_detection) == 0
    error_message = "Standard does not support Premium IDPS."
  }
  assert {
    condition     = length(azurerm_bastion_host.hub) == 0 && length(azurerm_network_security_group.bastion) == 0 && length(azurerm_virtual_network_gateway.vpn) == 0
    error_message = "Disabled optional services must not create resources."
  }
}
