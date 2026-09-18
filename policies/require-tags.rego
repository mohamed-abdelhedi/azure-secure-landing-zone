package landingzone

import rego.v1

required_tags := {"Environment", "Owner", "CostCenter", "Project"}

# Azure subnets, peerings, diagnostics and associations do not support tags.
tagged_types := {
	"azurerm_resource_group", "azurerm_virtual_network", "azurerm_network_security_group",
	"azurerm_route_table", "azurerm_public_ip", "azurerm_firewall", "azurerm_firewall_policy",
	"azurerm_virtual_network_gateway", "azurerm_bastion_host",
	"azurerm_log_analytics_workspace", "azurerm_monitor_action_group", "azurerm_storage_account",
}

deny contains sprintf("%s: missing or empty tag %s", [r.address, tag]) if {
	some r in resources
	r.type in tagged_types
	some tag in required_tags
	tags := object.get(r.change.after, "tags", {})
	not nonempty_tag(tags, tag)
}

nonempty_tag(tags, tag) if {
	is_string(tags[tag])
	trim_space(tags[tag]) != ""
}

deny contains sprintf("%s: Environment tag must be dev, staging or prod", [r.address]) if {
	some r in resources
	r.type in tagged_types
	tags := object.get(r.change.after, "tags", {})
	not object.get(tags, "Environment", "") in {"dev", "staging", "prod"}
}
