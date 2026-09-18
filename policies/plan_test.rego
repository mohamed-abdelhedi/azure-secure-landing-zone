package landingzone_test

import data.landingzone

test_global_not_allowed_for_vnet if {
	not landingzone.allow with input as plan("azurerm_virtual_network", {"location": "global", "tags": tags})
}

import rego.v1

tags := {"Environment": "dev", "Owner": "Platform", "CostCenter": "IT", "Project": "Landing Zone"}

plan(kind, values) := {
	"format_version": "1.2",
	"resource_changes": [{
		"address": "module.example.resource.test", "mode": "managed", "type": kind,
		"change": {"actions": ["create"], "after": values, "after_unknown": {}},
	}],
}

test_valid_nested_resource if {
	landingzone.allow with input as plan("azurerm_virtual_network", {"location": "eastus", "tags": tags})
}

test_disallowed_region if {
	not landingzone.allow with input as plan("azurerm_virtual_network", {"location": "westeurope", "tags": tags})
}

test_missing_tag if {
	not landingzone.allow with input as plan("azurerm_virtual_network", {"location": "eastus", "tags": object.remove(tags, ["Owner"])})
}

test_blank_tag if {
	not landingzone.allow with input as plan("azurerm_virtual_network", {"location": "eastus", "tags": object.union(tags, {"Owner": "  "})})
}

test_unknown_tags if {
	not landingzone.allow with input as plan("azurerm_virtual_network", {"location": "eastus", "tags": null})
}

test_invalid_environment if {
	not landingzone.allow with input as plan("azurerm_virtual_network", {"location": "eastus", "tags": object.union(tags, {"Environment": "other"})})
}

test_subnets_do_not_require_unsupported_tags if {
	landingzone.allow with input as plan("azurerm_subnet", {"name": "workload"})
}

test_global_action_group if {
	landingzone.allow with input as plan("azurerm_monitor_action_group", {"location": "global", "tags": tags})
}

secure_storage := {
	"location": "eastus", "tags": tags, "public_network_access_enabled": false,
	"enable_https_traffic_only": true, "min_tls_version": "TLS1_2", "allow_nested_items_to_be_public": false,
}

test_private_storage if {
	landingzone.allow with input as plan("azurerm_storage_account", secure_storage)
}

test_public_storage if {
	not landingzone.allow with input as plan("azurerm_storage_account", object.union(secure_storage, {"public_network_access_enabled": true}))
}

test_http_storage if {
	not landingzone.allow with input as plan("azurerm_storage_account", object.union(secure_storage, {"enable_https_traffic_only": false}))
}

test_old_tls if {
	not landingzone.allow with input as plan("azurerm_storage_account", object.union(secure_storage, {"min_tls_version": "TLS1_0"}))
}

test_unknown_storage_access if {
	not landingzone.allow with input as plan("azurerm_storage_account", object.remove(secure_storage, ["public_network_access_enabled"]))
}

test_public_nested_storage if {
	not landingzone.allow with input as plan("azurerm_storage_account", object.union(secure_storage, {"allow_nested_items_to_be_public": true}))
}

test_premium_idps_deny if {
	landingzone.allow with input as plan("azurerm_firewall_policy", {"sku": "Premium", "tags": tags, "intrusion_detection": [{"mode": "Deny"}]})
}

test_premium_idps_alert_denied if {
	not landingzone.allow with input as plan("azurerm_firewall_policy", {"sku": "Premium", "tags": tags, "intrusion_detection": [{"mode": "Alert"}]})
}

test_standard_has_no_idps_requirement if {
	landingzone.allow with input as plan("azurerm_firewall_policy", {"sku": "Standard", "tags": tags})
}

test_deletions_are_not_treated_as_creates if {
	p := plan("azurerm_virtual_network", {})
	deleted := object.union(p, {"resource_changes": [object.union(p.resource_changes[0], {"change": {"actions": ["delete"], "after": null}})]})
	landingzone.allow with input as deleted
}

test_replacements_checked if {
	p := plan("azurerm_storage_account", secure_storage)
	replacement := object.union(p, {"resource_changes": [object.union(p.resource_changes[0], {"change": {"actions": ["delete", "create"], "after": object.union(secure_storage, {"public_network_access_enabled": true})}})]})
	not landingzone.allow with input as replacement
}

test_bad_document_fails_closed if {
	not landingzone.allow with input as {}
	count(landingzone.deny) > 0 with input as {}
}

test_hcl_shaped_document_rejected if {
	not landingzone.allow with input as {"resource": {}}
}

test_empty_plan if {
	landingzone.allow with input as {"format_version": "1.2", "resource_changes": []}
}

test_unknown_location_denied if {
	p := plan("azurerm_virtual_network", {"tags": tags})
	unknown := object.union(p, {"resource_changes": [object.union(p.resource_changes[0], {"change": {"after": {"tags": tags}, "after_unknown": {"location": true}}})]})
	not landingzone.allow with input as unknown
}
