resource "azurerm_log_analytics_workspace" "azure_monitor_workspace" {
  name                = "log-${var.environment}-${var.location}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days

  tags = merge(
    var.tags,
    {
      "Purpose" = "Monitoring"
    }
  )
}

resource "azurerm_sentinel_log_analytics_workspace_onboarding" "azure_monitor_sentinel" {
  workspace_id                 = azurerm_log_analytics_workspace.azure_monitor_workspace.id
  customer_managed_key_enabled = false
}

resource "azurerm_monitor_action_group" "critical_alerts_action" {
  name                = "CriticalAlertsAction"
  resource_group_name = var.resource_group_name
  short_name          = "p0action"

  email_receiver {
    name          = "sendtoadmin"
    email_address = var.admin_email
  }
}
