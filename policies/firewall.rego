package landingzone

import rego.v1

deny contains sprintf("%s: Premium firewall policy must use IDPS Deny mode", [r.address]) if {
	some r in resources
	r.type == "azurerm_firewall_policy"
	r.change.after.sku == "Premium"
	not idps_deny(r.change.after)
}

idps_deny(after) if {
	some config in after.intrusion_detection
	config.mode == "Deny"
}
