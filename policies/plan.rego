package landingzone

import rego.v1

# Consume terraform show -json, not HCL-shaped input.
deny contains "Expected a Terraform plan with format_version and resource_changes" if {
	not valid_plan
}

valid_plan if {
	is_string(input.format_version)
	startswith(input.format_version, "1.")
	is_array(input.resource_changes)
}

resources contains r if {
	some r in input.resource_changes
	r.mode == "managed"
	is_object(r.change.after)
}

default allow := false

allow if {
	valid_plan
	count(deny) == 0
}
