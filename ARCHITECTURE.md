# Architecture and security decisions

This document describes the Terraform implementation in this repository. The older PNG diagrams under `docs/diagrams` show possible extensions and must not be used as deployment evidence.

## Network boundaries

Each root creates one resource group, one hub VNet and two spoke VNets. Peerings carry forwarded traffic. Each spoke subnet has an NSG and a route table whose default route points to Azure Firewall.

A default route does not force every packet through the firewall: more-specific routes, same-VNet traffic, peering and service endpoints can bypass that path. The spoke NSGs currently retain Azure's default VNet access behavior. This is an egress-inspection foundation, not complete east-west microsegmentation.

| Subnet | Prefix | Purpose |
| :--- | :--- | :--- |
| AzureFirewallSubnet | 10.0.0.0/26 | Firewall |
| GatewaySubnet | 10.0.1.0/26 | VPN gateway, prod only |
| AzureBastionSubnet | 10.0.2.0/26 | Bastion |
| App: aks | 10.1.0.0/22 | Reserved workload subnet; no AKS cluster |
| App: appgw | 10.1.4.0/24 | Reserved ingress subnet; no Application Gateway |
| Data: data | 10.2.0.0/24 | Reserved data subnet; no database |
| Data: privatelink | 10.2.1.0/24 | Reserved endpoint subnet; no private endpoints |

The VPN resource has BGP enabled but no on-premises connection or ExpressRoute circuit is configured. Dev/prod reuse IP ranges and require redesign before interconnecting.

## Firewall and administrative access

Both environments deny known malicious traffic using threat intelligence. Production's Premium policy uses IDPS Deny; development uses Standard and has no IDPS block. TLS inspection is intentionally absent because a CA certificate, trust distribution, managed identity and inspection rules require a separate design.

The baseline firewall allows DNS/NTP and selected Microsoft update/monitoring destinations. These are examples to adapt and test against workload requirements. DNS proxy is enabled, but VNet DNS is not configured to force clients to use it.

Bastion has an NSG with the eight required service rules and explicit deny rules for other traffic. See [Microsoft's Bastion NSG requirements](https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg). Firewall, Bastion and the prod VPN use public service IPs. Bastion removes the need for public IPs on future administrative target VMs; it does not make all infrastructure private.

## Logging and detection

Firewall diagnostic logs and metrics target a Log Analytics workspace using resource-specific tables. Sentinel is onboarded to that workspace. An email action group is available for future alert rules. No analytics rule or automation playbook is created, so onboarding alone does not demonstrate detections, alert delivery, machine learning or SOAR.

## Policy enforcement

OPA consumes `terraform show -json` output through `resource_changes`, including resources inside child modules. It checks the post-change values for creates, updates, replacements and no-ops; deleted resources have no post-change values and are excluded.

- Required tags apply to the taggable resource types managed here, not Azure subnets or associations.
- Regional resources must use eastus, eastus2, westus2 or centralus; global action groups are allowed.
- Storage accounts require private network access, HTTPS, TLS 1.2 and disabled public nested items. No workload storage account is currently provisioned; this protects future additions.
- Premium firewall policies require IDPS Deny.
- Unknown critical storage settings, unknown locations, malformed input and evaluator failures block evaluation.

These checks are bounded guardrails, not a comprehensive cloud compliance framework. The [OPA Terraform guidance](https://www.openpolicyagent.org/docs/terraform) describes limitations of plan-time values. Policy evaluation is included in both the local helper and manual deployment workflow, immediately before any apply of the saved plan.

## Credentials and state

Root modules own provider configuration. The hub no longer declares its own configured provider, which allows root-level dependencies and mock tests to work correctly.

The AzureRM provider remains at 3.117.1 and is locked for repeatable installs. Backend details live in ignored local files or GitHub environment variables. Dev and prod use different state keys. Entra/OIDC identities need resource deployment permissions and explicit backend data-plane access; no workflow stores a long-lived client secret.

Bootstrap scripts enable TLS 1.2, HTTPS, disable anonymous blobs and shared-key access, and enable blob versioning/soft-delete. The endpoint remains publicly routable with authenticated access; add network restrictions/private endpoints and a suitable runner for stricter state isolation.

## Validation and remaining evidence

Terraform validation and mocked plan tests exercise both environments and hub security settings. OPA tests cover good/bad plans, nested resources, missing/unknown values and deletion/replacement handling. CLI tests cover fail-closed behavior. Blocking Checkov and Trivy scans run in CI.

Mocked tests do not validate Azure API behavior, identity permissions, capacity/quotas, routing, actual log delivery or operating costs. Those require a real deployment, which is not performed by CI on pushes or pull requests.
