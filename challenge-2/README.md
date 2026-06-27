# Challenge 2: Azure Kubernetes Service (AKS) Deployment & Operations

## Requirements

Provision a production-ready AKS cluster, deploy a multi-tier application using Helm charts, implement monitoring/auto-scaling, and enforce security best practices.

## Solution Architecture

```
terraform-azurerm-aks (reusable module, v1.0.0)
  └── challenge-2/ (this folder — deployment code)
        ├── envs/dev.tfvars    → eastus
        └── envs/prod.tfvars   → westeurope

Platform & Application (deployed after cluster creation)
├── aks-platform-config     → Gatekeeper + NGINX Ingress + OPA policies
├── aks-app-deployment      → Helm umbrella chart (frontend + backend + database)
├── helm-gatekeeper         → Gatekeeper Helm values
└── helm-ingress-nginx      → NGINX Ingress Helm values
```

### Repos

| Repo | Purpose |
|---|---|
| [terraform-azurerm-aks](https://github.com/KT-MakeDevOpsEasy/terraform-azurerm-aks) | Reusable AKS module |
| [terraform-azurerm-vnet](https://github.com/KT-MakeDevOpsEasy/terraform-azurerm-vnet) | Reusable VNET module (used for AKS networking) |
| [terraform-azure-aks-deployment](https://github.com/KT-MakeDevOpsEasy/terraform-azure-aks-deployment) | Standalone deployment repo (same code as this folder) |
| [aks-platform-config](https://github.com/KT-MakeDevOpsEasy/aks-platform-config) | OPA/Gatekeeper policies, bootstrap script |
| [aks-app-deployment](https://github.com/KT-MakeDevOpsEasy/aks-app-deployment) | Multi-tier Helm umbrella chart |
| [helm-gatekeeper](https://github.com/KT-MakeDevOpsEasy/helm-gatekeeper) | Gatekeeper Helm configuration |
| [helm-ingress-nginx](https://github.com/KT-MakeDevOpsEasy/helm-ingress-nginx) | NGINX Ingress Helm configuration |

## Design Decisions

### AKS Cluster

| Decision | Choice | Why |
|---|---|---|
| **Network plugin** | Azure CNI | Pods get real VNET IPs, full network policy support, no NAT overhead |
| **Network policy** | Calico | Richer policy language than Azure native provider |
| **Node pools** | System + Workload | System pool isolated with CriticalAddonsOnly taint, workload pool scales independently |
| **Identity** | User-assigned managed identity | No credential rotation needed, unlike service principals |
| **Workload identity** | OIDC + federated credentials | Pods authenticate to Azure without storing secrets |
| **API server** | Authorized IP ranges (dev), private cluster (prod recommended) | Balance accessibility vs security per environment |
| **Autoscaling** | Cluster autoscaler on both pools | 10m scale-down delay, 50% utilization threshold |

### Helm Application Stack

| Tier | Image | Features |
|---|---|---|
| Frontend | nginx:1.25-alpine | Ingress, HPA, NetworkPolicy, liveness/readiness probes |
| Backend | python:3.12-slim | ConfigMap, Secrets, HPA, NetworkPolicy, startup/liveness/readiness probes |
| Database | postgres:16-alpine | StatefulSet, PVC, pg_isready probes, Helm hooks for secrets |

**Umbrella chart** pattern — single `helm install` deploys all 3 tiers with environment-specific values.

### Security

- **Pod security**: `runAsNonRoot`, `readOnlyRootFilesystem`, `drop ALL capabilities` on all containers
- **Network segmentation**: Calico NetworkPolicies enforce Frontend → Backend → Database flow
- **Admission control**: OPA/Gatekeeper with required labels and allowed registries constraints
- **Secrets**: Key Vault with CSI driver, External Secrets Operator pattern for prod
- **Image scanning**: Gatekeeper constraint restricts to ACR + trusted registries only

### Monitoring & Auto-Scaling

- **Container Insights** via OMS agent → Log Analytics workspace
- **HPA**: Frontend/Backend scale on CPU (60% target), 3-20 replicas in prod
- **Cluster autoscaler**: Tuned profile (10m cooldown, 50% utilization threshold)
- **Alerts**: Documented thresholds for CPU, memory, pod restarts, PVC usage

### Feature Flags

Resources toggled per environment via tfvars:
- `enable_acr` — Azure Container Registry
- `enable_keyvault` — Azure Key Vault
- `enable_log_analytics` — Log Analytics workspace

## Usage

```bash
# Set Azure credentials
az login
export TF_VAR_subscription_id=$(az account show --query id -o tsv)

# Bootstrap state storage (first time only)
./scripts/bootstrap-state.sh

# Deploy AKS infrastructure
terraform init -backend-config=backends/dev.backend.hcl
terraform plan -var-file=envs/dev.tfvars
terraform apply -var-file=envs/dev.tfvars

# Bootstrap platform (Gatekeeper + Ingress + policies)
# This is automated in CI/CD, but can be run manually:
az aks get-credentials --resource-group rg-demo-dev-eus --name aks-demo-dev-eus
git clone https://github.com/KT-MakeDevOpsEasy/aks-platform-config.git
cd aks-platform-config && ./scripts/bootstrap.sh dev

# Deploy application
git clone https://github.com/KT-MakeDevOpsEasy/aks-app-deployment.git
cd aks-app-deployment/helm/multi-tier-app
helm dependency update .
helm install multi-tier-app . --namespace app-dev --create-namespace -f values-dev.yaml
```

## CI/CD Pipeline

| Event | Branch | Action |
|---|---|---|
| PR → `dev` | dev | Lint + Plan dev |
| Push → `dev` | dev | Apply dev + Bootstrap platform |
| PR → `main` | main | Lint + Plan prod |
| Push → `main` | main | Apply prod (with approval) + Bootstrap platform |

Platform bootstrap (Gatekeeper + NGINX Ingress + OPA policies) runs automatically after each `terraform apply`.
