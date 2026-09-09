package terraform.azure.tagging

import future.keywords.in

required_tags := ["Environment", "Owner", "CostCenter", "Project"]

# Deny resources without required tags
deny[msg] {
    resource := input.resource[resource_type][name]
    resource_type in ["azurerm_resource_group", "azurerm_virtual_network", "azurerm_subnet"]
    
    missing_tags := [tag | tag := required_tags[_]; not resource.tags[tag]]
    count(missing_tags) > 0
    
    msg := sprintf("Resource '%s' of type '%s' is missing required tags: %v", [name, resource_type, missing_tags])
}

# Validate Environment tag values
deny[msg] {
    resource := input.resource[_][name]
    env := resource.tags.Environment
    not env in ["dev", "staging", "prod"]
    
    msg := sprintf("Resource '%s' has invalid Environment tag value '%s'. Must be dev, staging, or prod.", [name, env])
}
