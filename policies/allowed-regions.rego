package landingzone

import rego.v1

allowed_regions := {"eastus", "eastus2", "westus2", "centralus"}

deny contains sprintf("%s: location must be an approved region", [r.address]) if {
	some r in resources
	location := object.get(r.change.after, "location", null)
	location != null
	not global_service(r.type, location)
	not location in allowed_regions
}

global_service(kind, location) if {
	kind == "azurerm_monitor_action_group"
	location == "global"
}

deny contains sprintf("%s: location must be known at plan time", [r.address]) if {
	some r in resources
	object.get(object.get(r.change, "after_unknown", {}), "location", false) == true
}
