# Azure DevOps Technical Challenges

This repository contains the implementation for two Azure infrastructure challenges, demonstrating production-grade Terraform module design, AKS deployment, and Kubernetes operations.

## Organization: [KT-MakeDevOpsEasy](https://github.com/KT-MakeDevOpsEasy)

## Challenges

| Challenge | Description | Folder |
|---|---|---|
| [Challenge 1](challenge-1/) | Provision Azure VNET infrastructure with reusable Terraform modules | `challenge-1/` |
| [Challenge 2](challenge-2/) | AKS deployment, Helm charts, monitoring, and security | `challenge-2/` |

## Architecture Overview

```
Reusable Modules (versioned, tagged v1.0.0)
├── terraform-azurerm-vnet          → VNET + Subnets + NSGs + DDoS + enforced tags
└── terraform-azurerm-aks           → AKS + Node Pools + Identity + Autoscaler + enforced tags

Deployments (this repo)
├── challenge-1/                    → VNET + VM + Storage (uses terraform-azurerm-vnet)
└── challenge-2/                    → AKS + ACR + KeyVault + Log Analytics (uses both modules)

Platform & Application
├── aks-platform-config             → Gatekeeper + NGINX Ingress bootstrap + OPA policies
├── aks-app-deployment              → Helm umbrella chart (frontend + backend + database)
├── helm-gatekeeper                 → Gatekeeper Helm values
└── helm-ingress-nginx              → NGINX Ingress Helm values
```

## Quick Start

```bash
# 1. Login to Azure
az login
export TF_VAR_subscription_id=$(az account show --query id -o tsv)

# 2. Bootstrap state storage
cd challenge-1
./scripts/bootstrap-state.sh

# 3. Deploy VNET (Challenge 1)
terraform init -backend-config=backends/dev.backend.hcl
terraform plan -var-file=envs/dev.tfvars
terraform apply -var-file=envs/dev.tfvars

# 4. Deploy AKS (Challenge 2)
cd ../challenge-2
terraform init -backend-config=backends/dev.backend.hcl
terraform plan -var-file=envs/dev.tfvars
terraform apply -var-file=envs/dev.tfvars
```
