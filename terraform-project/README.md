# 🚀 Azure Landing Zone - Production-Grade Terraform Project

## 📋 Overview

This Terraform project implements a **secure, scalable, and cost-optimized Azure landing zone** following enterprise best practices and the Azure Cloud Adoption Framework.

## 🏗️ Architecture

See `../ARCHITECTURE_GUIDE.md` for detailed architecture documentation.

## 🚀 Quick Start

### Prerequisites

- Azure CLI installed and authenticated
- Terraform >= 1.6.0
- Azure subscription with Contributor access

### 1. Initialize Backend

```bash
cd scripts
./init-backend.sh
```

### 2. Deploy to Dev Environment

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

## 📁 Project Structure

```
terraform-project/
├── modules/              # Reusable Terraform modules
├── environments/         # Environment-specific configurations
├── policies/            # Azure Policy and OPA policies
└── scripts/             # Helper scripts
```

## 🔐 Security Features

- ✅ Zero Trust architecture with Private Link
- ✅ Azure Firewall Premium with IDPS
- ✅ Managed Identities (no passwords in code)
- ✅ Key Vault for secrets management
- ✅ Network Security Groups and Application Security Groups
- ✅ Just-In-Time VM access

## 📊 Cost Optimization

- Azure Policy enforces tagging for cost tracking
- Right-sized VM SKUs based on environment
- Auto-scaling for AKS node pools
- Reserved instances for production workloads

## 🤖 DevSecOps Integration

CI/CD pipelines include:
- Checkov for Terraform security scanning
- Trivy for container vulnerability scanning
- OPA for policy enforcement
- Automated testing with Terratest

## 📝 Naming Conventions

All resources follow this pattern:
```
<resource-type>-<workload>-<environment>-<region>-<instance>
```

Example: `vnet-hub-prod-eastus-001`

## 🌍 Multi-Environment Strategy

| Environment | Purpose | Auto-Approve |
|-------------|---------|--------------|
| Dev | Development and testing | ✅ Yes |
| Staging | Pre-production validation | ❌ No |
| Prod | Production workloads | ❌ No (requires manual approval) |

## 📞 Support

For questions or issues, please contact the Cloud Platform Team.
