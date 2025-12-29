output "workspace_id" {
  description = "workspace ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.AzureMonitorWorkspace.id
}
output "workspace_primary_shared_key" {
  description = "Primary shared key of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.AzureMonitorWorkspace.primary_shared_key
  sensitive   = true
}

output "workspace_name" {
  description = "Name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.AzureMonitorWorkspace.name
}
output "sentinel_onboarding_id" {
  description = "ID of the Sentinel Log Analytics Workspace Onboarding"
  value       = azurerm_sentinel_log_analytics_workspace_onboarding.azure_monitor_sentinel.id
}