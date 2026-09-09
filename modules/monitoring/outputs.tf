output "workspace_id" {
  description = "Workspace ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.azure_monitor_workspace.id
}

output "workspace_primary_shared_key" {
  description = "Primary shared key of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.azure_monitor_workspace.primary_shared_key
  sensitive   = true
}

output "workspace_name" {
  description = "Name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.azure_monitor_workspace.name
}

output "sentinel_onboarding_id" {
  description = "ID of the Sentinel Log Analytics Workspace Onboarding"
  value       = azurerm_sentinel_log_analytics_workspace_onboarding.azure_monitor_sentinel.id
}