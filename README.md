# Azure DevOps Technical Challenges

Two Azure infrastructure challenges demonstrating production-grade Terraform, AKS operations, Helm deployments, and CI/CD pipelines.

## Organization: [KT-MakeDevOpsEasy](https://github.com/KT-MakeDevOpsEasy)

## Challenges

| Challenge | What it Proves | Folder |
|---|---|---|
| [Challenge 1](challenge-1/) | Reusable Terraform modules, multi-env VNET + VM + Key Vault | `challenge-1/` |
| [Challenge 2](challenge-2/) | AKS cluster, Helm charts, OPA/Gatekeeper, monitoring, CI/CD | `challenge-2/` |

## Architecture Overview

```
Reusable Modules (versioned, separate repos)
├── terraform-azurerm-vnet          → VNET + Subnets + NSGs + DDoS + enforced tags
└── terraform-azurerm-aks           → AKS + Node Pools + Identity + Autoscaler + RBAC

Deployments (this repo)
├── challenge-1/                    → VNET + VM + KeyVault (uses vnet module)
└── challenge-2/                    → AKS + ACR + KeyVault + Log Analytics (uses both modules)

Platform & Application (challenge-2 post-deploy)
├── aks-platform-config             → Gatekeeper + ESO + Gateway API + OPA policies
├── aks-app-deployment              → Helm umbrella chart (frontend + backend + database)
└── helm-gatekeeper                 → Gatekeeper Helm configuration
```

## Repo Map

| Repo | Purpose |
|---|---|
| [terraform-azurerm-vnet](https://github.com/KT-MakeDevOpsEasy/terraform-azurerm-vnet) | Reusable VNET module with tests |
| [terraform-azurerm-aks](https://github.com/KT-MakeDevOpsEasy/terraform-azurerm-aks) | Reusable AKS module |
| [aks-platform-config](https://github.com/KT-MakeDevOpsEasy/aks-platform-config) | Platform bootstrap (Gatekeeper, ESO, Gateway API, OPA) |
| [aks-app-deployment](https://github.com/KT-MakeDevOpsEasy/aks-app-deployment) | Multi-tier Helm umbrella chart |
| [helm-gatekeeper](https://github.com/KT-MakeDevOpsEasy/helm-gatekeeper) | Gatekeeper Helm values |

## Quick Start

```bash
# 1. Login to Azure
az login
export TF_VAR_subscription_id=$(az account show --query id -o tsv)

# 2. Challenge 1: VNET
cd challenge-1
./scripts/bootstrap-state.sh dev
terraform init -backend-config=backends/dev.backend.hcl
terraform plan -var-file=envs/dev.tfvars
terraform apply -var-file=envs/dev.tfvars

# 3. Challenge 2: AKS
cd ../challenge-2
./scripts/bootstrap-state.sh dev
terraform init -backend-config=backends/dev.backend.hcl
terraform plan -var-file=envs/dev.tfvars
terraform apply -var-file=envs/dev.tfvars

# 4. Platform bootstrap
ACR_LOGIN_SERVER=$(az acr list -g rg-poc-dev-eus --query "[0].loginServer" -o tsv)
az aks get-credentials --resource-group rg-poc-dev-eus --name aks-poc-dev-eus
git clone https://github.com/KT-MakeDevOpsEasy/aks-platform-config.git
cd aks-platform-config && ./scripts/bootstrap.sh dev $ACR_LOGIN_SERVER

# 5. Deploy app
git clone https://github.com/KT-MakeDevOpsEasy/aks-app-deployment.git
cd aks-app-deployment/helm/multi-tier-app
helm dependency update .
helm upgrade --install multi-tier-app . --namespace app-dev --create-namespace -f values-dev.yaml
```

## Key Design Principles

- **Module reuse** — VNET and AKS are versioned, tested modules consumed via git tags
- **Environment isolation** — separate tfvars, backends, and state per env (dev/prod)
- **Security by default** — Azure RBAC, Gatekeeper policies, pod security contexts, network policies
- **CI/CD** — GitHub Actions with lint → plan → apply flow, environment approvals for prod
- **Naming convention** — `{type}-{project}-{env}-{region}` across all resources
