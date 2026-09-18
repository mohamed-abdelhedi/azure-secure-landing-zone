# Security model

This repository is a reference implementation. Report suspected credential exposure privately through [GitHub's vulnerability reporting](https://github.com/mohamed-abdelhedi/azure-secure-landing-zone/security/advisories/new), if available, or contact the maintainer through the profile's LinkedIn link. Do not place credentials or Terraform state in a public issue.

## Controls

- Push and pull-request workflows use read-only repository permissions and no Azure credentials.
- Manual deployment defaults to plan, is restricted to main, runs quality gates, authenticates through OIDC and checks the actual plan before apply.
- Production apply requires a configured environment reviewer rule. Environment reviewers, Azure federation and role assignments are external setup steps.
- Local apply/destroy always generate a fresh policy-checked plan and require typed confirmation.
- Checkov failures and high/critical Trivy findings block CI. Rego and Terraform tests are regression coverage, not certification.
- State, variable files, backend configuration and plans are ignored. Secret scans should include full Git history before sharing exports.

## Limits

The project has not been certified for production. Default VNet rules do not provide complete workload isolation. TLS inspection, Private Link, detection rules and response playbooks are not implemented. AzureRM 3.x is retained for compatibility and needs a planned upgrade. Review [ARCHITECTURE.md](ARCHITECTURE.md) before deploying.
