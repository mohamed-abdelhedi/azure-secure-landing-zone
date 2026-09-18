mock_provider "azurerm" {}

run "development_plan" {
  command = plan
  assert {
    condition     = azurerm_resource_group.dev.tags.Environment == "dev"
    error_message = "The dev root must carry dev tags."
  }
  assert {
    condition     = module.hub_network.vpn_gateway_id == null
    error_message = "The dev environment must not provision a VPN gateway."
  }
  assert {
    condition     = azurerm_monitor_diagnostic_setting.firewall.log_analytics_destination_type == "Dedicated"
    error_message = "Firewall diagnostics must use resource-specific tables."
  }
}

run "reject_environment_mismatch" {
  command = plan
  variables { environment = "prod" }
  expect_failures = [var.environment]
}

run "reject_unapproved_region" {
  command = plan
  variables { location = "westeurope" }
  expect_failures = [var.location]
}
