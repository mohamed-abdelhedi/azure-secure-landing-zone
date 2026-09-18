package landingzone

import rego.v1

storage_requirements := {
	"public_network_access_enabled": false,
	"enable_https_traffic_only": true,
	"min_tls_version": "TLS1_2",
	"allow_nested_items_to_be_public": false,
}

deny contains sprintf("%s: storage setting %s must equal %v and be known", [r.address, key, expected]) if {
	some r in resources
	r.type == "azurerm_storage_account"
	some key, expected in storage_requirements
	object.get(r.change.after, key, null) != expected
}
