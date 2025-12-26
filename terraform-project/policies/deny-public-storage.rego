package terraform.azure.storage

# Deny public access to storage accounts
deny[msg] {
    resource := input.resource.azurerm_storage_account[_]
    resource.public_network_access_enabled == true
    
    msg := sprintf("Storage account '%s' has public network access enabled. This violates security policy.", [resource.name])
}

# Require HTTPS-only traffic
deny[msg] {
    resource := input.resource.azurerm_storage_account[_]
    not resource.enable_https_traffic_only
    
    msg := sprintf("Storage account '%s' must enable HTTPS-only traffic.", [resource.name])
}

# Require minimum TLS version
deny[msg] {
    resource := input.resource.azurerm_storage_account[_]
    not resource.min_tls_version
    
    msg := sprintf("Storage account '%s' must specify minimum TLS version 1.2.", [resource.name])
}

deny[msg] {
    resource := input.resource.azurerm_storage_account[_]
    resource.min_tls_version != "TLS1_2"
    
    msg := sprintf("Storage account '%s' must use TLS 1.2 or higher.", [resource.name])
}
