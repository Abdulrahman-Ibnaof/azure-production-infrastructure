# Azure Production Infrastructure

<div align="center">

[![Terraform](https://img.shields.io/badge/Terraform-1.6%2B-7B42BC?logo=terraform)](https://www.terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Production-0078D4?logo=microsoftazure)](https://azure.microsoft.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![CI](https://github.com/YOUR_USERNAME/azure-production-infrastructure/actions/workflows/terraform.yml/badge.svg)](https://github.com/YOUR_USERNAME/azure-production-infrastructure/actions)

**Production-grade Azure infrastructure provisioned with Terraform following Microsoft's Well-Architected Framework.**

[Architecture](#architecture) · [Modules](#modules) · [Quick Start](#quick-start) · [Environments](#environments) · [Security](#security)

</div>

---

## Overview

This repository provisions a complete, production-ready Azure infrastructure including:

- **AKS** (Azure Kubernetes Service) with multi-node-pool, autoscaling, OIDC & Workload Identity
- **Azure Application Gateway WAFv2** for ingress with OWASP protection
- **PostgreSQL Flexible Server** with Zone-Redundant High Availability
- **Azure Container Registry (Premium)** with geo-replication
- **Key Vault (Premium)** with RBAC, private endpoints, and soft-delete
- **Log Analytics + Application Insights** with metric alerts
- **VNet** with segmented subnets and strict NSG rules

## Architecture

```
                        ┌─────────────────────────────────────────────────┐
                        │              Azure Subscription                  │
                        │                                                 │
                        │   ┌─────────────────────────────────────────┐   │
                        │   │         Resource Group (prod)            │   │
   Internet ───────────────►│                                         │   │
                        │   │  ┌──────────┐    ┌───────────────────┐  │   │
                        │   │  │ App GW   │    │    VNet 10.0/16   │  │   │
                        │   │  │  WAF v2  │───►│                   │  │   │
                        │   │  │ (zones)  │    │  ┌─────────────┐  │  │   │
                        │   │  └──────────┘    │  │ AKS Subnet  │  │  │   │
                        │   │                  │  │  10.0.0/22  │  │  │   │
                        │   │  ┌──────────┐    │  │             │  │  │   │
                        │   │  │   ACR    │    │  │ ┌─────────┐ │  │  │   │
                        │   │  │ Premium  │◄───┤  │ │  AKS    │ │  │  │   │
                        │   │  │ (geo-rep)│    │  │ │ Cluster │ │  │  │   │
                        │   │  └──────────┘    │  │ │ (zones) │ │  │  │   │
                        │   │                  │  │ └────┬────┘ │  │  │   │
                        │   │  ┌──────────┐    │  └──────┼──────┘  │  │   │
                        │   │  │  Key     │    │         │         │  │   │
                        │   │  │  Vault   │◄───┤  ┌──────▼──────┐  │  │   │
                        │   │  │ (RBAC)   │    │  │  DB Subnet  │  │  │   │
                        │   │  └──────────┘    │  │  10.0.4/24  │  │  │   │
                        │   │                  │  │             │  │  │   │
                        │   │  ┌──────────┐    │  │ ┌─────────┐ │  │  │   │
                        │   │  │   Log    │    │  │ │ PgSQL   │ │  │  │   │
                        │   │  │Analytics │◄───┤  │ │  HA-ZR  │ │  │  │   │
                        │   │  │+ AppInsights   │  │ └─────────┘ │  │  │   │
                        │   │  └──────────┘    │  └─────────────┘  │  │   │
                        │   │                  └───────────────────┘  │   │
                        │   └─────────────────────────────────────────┘   │
                        └─────────────────────────────────────────────────┘
```

## Modules

| Module | Description | Key Resources |
|--------|-------------|---------------|
| `networking` | Network foundation | VNet, Subnets, NSGs, App Gateway WAF v2, Private DNS |
| `aks` | Kubernetes cluster | AKS, node pools, OIDC, Workload Identity, Defender |
| `security` | Secrets & identity | Key Vault (Premium), Private Endpoint, RBAC |
| `database` | Managed database | PostgreSQL Flexible, Zone-Redundant HA |
| `storage` | Registries & blobs | ACR Premium, Storage Account with versioning |
| `monitoring` | Observability | Log Analytics, App Insights, Metric Alerts |

## Quick Start

### Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Terraform | ≥ 1.6 | [docs](https://developer.hashicorp.com/terraform/install) |
| Azure CLI | ≥ 2.55 | [docs](https://learn.microsoft.com/cli/azure/install-azure-cli) |
| kubectl | ≥ 1.29 | [docs](https://kubernetes.io/docs/tasks/tools/) |

### 1. Bootstrap remote state (run once)

```bash
# Creates storage account for Terraform state
bash scripts/bootstrap.sh eastus2
```

### 2. Set environment variables

```bash
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"
export ARM_TENANT_ID="<your-tenant-id>"
export ARM_CLIENT_ID="<service-principal-client-id>"
export ARM_CLIENT_SECRET="<service-principal-secret>"
```

### 3. Deploy

```bash
# Development
make init ENV=dev
make plan ENV=dev
make apply ENV=dev

# Production
make init ENV=prod
make plan ENV=prod
make apply ENV=prod
```

### 4. Connect to AKS

```bash
make kubeconfig ENV=prod
kubectl get nodes -o wide
```

## Environments

| Environment | AKS Tier | Node VM | DB SKU | HA | Geo-Redundancy |
|------------|----------|---------|--------|----|----------------|
| `dev` | Free | B2ms | B_Standard_B1ms | ❌ | ❌ |
| `staging` | Standard | D4ds_v5 | GP_D2ds_v4 | ✅ | ❌ |
| `prod` | Standard | D8ds_v5 | GP_D4ds_v4 | ✅ (Zone-Redundant) | ✅ |

## Security

This infrastructure implements the following security controls:

- **Network**: Private AKS cluster (prod), strict NSG rules, private endpoints for Key Vault
- **Identity**: Workload Identity (no static secrets), RBAC-only Key Vault, OIDC issuer enabled
- **Data**: TLS 1.2 minimum, encryption at rest (customer-managed keys ready), PostgreSQL SSL enforced
- **Container**: ACR with content trust, AKS Microsoft Defender enabled, Azure Policy add-on
- **Audit**: All Key Vault operations logged to Log Analytics, Azure Monitor metric alerts
- **WAF**: OWASP 3.2 ruleset in Prevention mode on Application Gateway

### Static Analysis

```bash
# Security scanning (runs in CI automatically)
make lint

# Or manually
tfsec . --tfvars-file environments/prod/terraform.tfvars
checkov -d . --framework terraform
```

## CI/CD

GitHub Actions pipeline runs on every PR and push to `main`:

1. **Security Scan** — tfsec + Checkov with SARIF upload to GitHub Security tab
2. **Validate** — `terraform fmt` check + `terraform validate`
3. **Plan** — posts plan diff as PR comment
4. **Apply** — runs automatically on merge to `main` (dev) or manual approval (prod)

### Required GitHub Secrets

```
AZURE_CLIENT_ID
AZURE_CLIENT_SECRET
AZURE_SUBSCRIPTION_ID
AZURE_TENANT_ID
```

## Cost Estimation (prod, East US 2)

| Resource | Approx. Monthly Cost |
|----------|---------------------|
| AKS (Standard tier + 6× D8ds_v5 nodes) | ~$900 |
| Application Gateway WAF v2 | ~$250 |
| PostgreSQL GP_D4ds_v4 (HA) | ~$400 |
| ACR Premium + geo-replication | ~$100 |
| Log Analytics (90-day retention) | ~$80 |
| Key Vault Premium | ~$5 |
| **Total** | **~$1,735/month** |

> Use `make plan ENV=dev` to deploy a ~$150/month dev environment.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
