mock_provider "azurerm" {}

run "production_plan" {
  command = plan
  assert {
    condition     = azurerm_resource_group.prod.tags.Environment == "prod"
    error_message = "The prod root must carry prod tags."
  }
  assert {
    condition     = azurerm_monitor_diagnostic_setting.firewall.log_analytics_destination_type == "Dedicated"
    error_message = "Firewall diagnostics must use resource-specific tables."
  }
}

run "reject_environment_mismatch" {
  command = plan
  variables { environment = "dev" }
  expect_failures = [var.environment]
}

run "reject_unapproved_region" {
  command = plan
  variables { location = "westeurope" }
  expect_failures = [var.location]
}
