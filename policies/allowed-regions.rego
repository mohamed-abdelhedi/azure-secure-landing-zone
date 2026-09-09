package terraform.azure.regions

import future.keywords.in

allowed_regions := ["eastus", "eastus2", "westus2", "centralus"]

# Deny resources in non-approved regions
deny[msg] {
    resource := input.resource[resource_type][name]
    location := resource.location
    not location in allowed_regions
    
    msg := sprintf("Resource '%s' of type '%s' is being deployed to region '%s'. Only these regions are allowed: %v", 
        [name, resource_type, location, allowed_regions])
}
