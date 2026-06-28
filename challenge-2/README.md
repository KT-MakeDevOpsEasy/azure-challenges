# Challenge 2: AKS Deployment & Operations

## Objective

Provision a production-ready AKS cluster, deploy a multi-tier application using Helm charts, enforce security policies with OPA/Gatekeeper, and implement monitoring and auto-scaling.

## Solution Architecture

```
terraform-azurerm-vnet (reusable module)
terraform-azurerm-aks  (reusable module)
  └── challenge-2/ (this folder — infrastructure code)
        ├── envs/dev.tfvars    → eastus     (rg-poc-dev-eus)
        ├── envs/prod.tfvars   → westeurope (rg-poc-prod-weu)
        ├── backends/          → per-env Azure Storage state backends
        └── rbac.tf            → AKS RBAC role assignments

Platform Bootstrap (deployed after cluster creation)
├── aks-platform-config     → Gatekeeper + ESO + Gateway API CRDs + OPA policies
├── aks-app-deployment      → Helm umbrella chart (frontend + backend + database)
└── helm-gatekeeper         → Gatekeeper Helm values
```

### Repos

| Repo | Purpose |
|---|---|
| [terraform-azurerm-aks](https://github.com/KT-MakeDevOpsEasy/terraform-azurerm-aks) | Reusable AKS module (CNI Overlay, Cilium, RBAC, autoscaler) |
| [terraform-azurerm-vnet](https://github.com/KT-MakeDevOpsEasy/terraform-azurerm-vnet) | Reusable VNET module (subnets, NSGs, tests) |
| [aks-platform-config](https://github.com/KT-MakeDevOpsEasy/aks-platform-config) | Platform bootstrap script + OPA policies |
| [aks-app-deployment](https://github.com/KT-MakeDevOpsEasy/aks-app-deployment) | Multi-tier Helm umbrella chart |
| [helm-gatekeeper](https://github.com/KT-MakeDevOpsEasy/helm-gatekeeper) | Gatekeeper Helm configuration |

## Design Decisions

### AKS Cluster

| Decision | Choice | Why |
|---|---|---|
| **Network plugin** | Azure CNI Overlay | Pod IPs from overlay CIDR, preserves VNET address space |
| **Network policy** | Cilium (eBPF) | Supports Gateway API, better performance than Calico, built-in observability |
| **Node pools** | System + Workload | System pool isolated, workload pool scales independently |
| **Identity** | User-assigned managed identity | No credential rotation needed, unlike service principals |
| **Workload identity** | OIDC + federated credentials | Pods authenticate to Azure without storing secrets |
| **API server** | Authorized IP ranges (dev) | Balance accessibility vs security per environment |
| **Autoscaling** | Cluster autoscaler | 10m scale-down delay, 50% utilization threshold |

### Platform Components

| Component | Purpose | Dev | Prod |
|---|---|---|---|
| **OPA/Gatekeeper** | Admission control (allowed registries, required labels) | dryrun (audit) | deny (enforce) |
| **External Secrets Operator** | Sync secrets from Azure Key Vault | Installed | Installed |
| **Gateway API CRDs** | Ingress via Cilium Gateway API | Installed | Installed |

### Helm Application Stack

| Tier | Image | Key Features |
|---|---|---|
| Frontend | nginx:1.25-alpine | Gateway API ingress, HPA, NetworkPolicy, liveness/readiness probes |
| Backend | python:3.12-slim | ConfigMap, Secrets, HPA, NetworkPolicy, startup/liveness/readiness probes |
| Database | postgres:16-alpine | StatefulSet, PVC, pg_isready probes |

**Umbrella chart** pattern — single `helm install` deploys all 3 tiers with environment-specific values.

### Security

| Layer | Implementation |
|---|---|
| **Pod security** | `runAsNonRoot`, `readOnlyRootFilesystem`, `drop ALL capabilities` |
| **Network segmentation** | Cilium NetworkPolicies: Frontend ← any, Backend ← frontend, Database ← backend |
| **Admission control** | OPA/Gatekeeper: required labels + allowed registries (dryrun in dev, deny in prod) |
| **Secrets** | External Secrets Operator + Azure Key Vault |
| **RBAC** | Azure AD RBAC on AKS, role assignments via Terraform |
| **Image policy** | Gatekeeper constraint restricts to ACR + docker.io + mcr.microsoft.com |

### Monitoring & Auto-Scaling

| Feature | Configuration |
|---|---|
| **Container Insights** | OMS agent → Log Analytics workspace |
| **HPA** | Frontend/Backend scale on CPU (60% target, 3-20 replicas in prod) |
| **Cluster autoscaler** | 10m cooldown, 50% utilization threshold |
| **Alerts** | CPU, memory, pod restarts, PVC usage thresholds |

## Environments

| | Dev | Prod |
|---|---|---|
| **Region** | eastus | westeurope |
| **SKU Tier** | Free | Standard |
| **System Pool** | 1-2 nodes, 1 AZ | 2-5 nodes, 3 AZs |
| **Workload Pool** | None | 2-10 nodes, 3 AZs |
| **ACR** | Basic | Premium (private endpoint) |
| **Key Vault** | Disabled | Enabled (purge protection on) |
| **Log Analytics** | 30-day retention | 90-day retention |
| **Gatekeeper** | dryrun (audit only) | deny (enforced) |
| **Alerts** | Disabled | Enabled |

### Feature Flags (tfvars)

- `enable_acr` — Azure Container Registry
- `enable_keyvault` — Azure Key Vault
- `enable_log_analytics` — Log Analytics workspace
- `enable_alerts` — Azure Monitor metric alerts

## Usage

```bash
# 1. Login to Azure
az login
export TF_VAR_subscription_id=$(az account show --query id -o tsv)

# 2. Bootstrap state storage (first time only)
./scripts/bootstrap-state.sh dev

# 3. Deploy infrastructure
terraform init -backend-config=backends/dev.backend.hcl
terraform plan -var-file=envs/dev.tfvars
terraform apply -var-file=envs/dev.tfvars

# 4. Bootstrap platform (Gatekeeper + ESO + Gateway API + OPA policies)
ACR_LOGIN_SERVER=$(az acr list -g rg-poc-dev-eus --query "[0].loginServer" -o tsv)
az aks get-credentials --resource-group rg-poc-dev-eus --name aks-poc-dev-eus
git clone https://github.com/KT-MakeDevOpsEasy/aks-platform-config.git
cd aks-platform-config && ./scripts/bootstrap.sh dev $ACR_LOGIN_SERVER

# 5. Deploy application
git clone https://github.com/KT-MakeDevOpsEasy/aks-app-deployment.git
cd aks-app-deployment/helm/multi-tier-app
helm dependency update .
helm upgrade --install multi-tier-app . --namespace app-dev --create-namespace -f values-dev.yaml

# 6. Verify
kubectl get pods -n app-dev
kubectl get constraints -o custom-columns=NAME:.metadata.name,ACTION:.spec.enforcementAction
```

## CI/CD Pipeline

| Event | Branch | Action |
|---|---|---|
| PR → `dev` | dev | Lint + Validate + Plan (posted as PR comment) |
| Push → `dev` | dev | Plan + Apply + Platform bootstrap + App deploy |
| PR → `main` | main | Lint + Validate + Plan (posted as PR comment) |
| Push → `main` | main | Plan + Apply (with approval) + Platform bootstrap |

### Pipeline Features

- Terraform outputs drive downstream steps (resource group, cluster name, ACR)
- `kubelogin` for AAD-enabled AKS authentication in CI
- Platform bootstrap runs after every apply (idempotent)

### Release Flow

```
feature branch ── PR → dev ── review plan ── squash merge ── apply + bootstrap
                                                                │
                                              PR → main ── review plan ── merge ── apply + bootstrap (with approval)
```

## State Management

| Environment | Resource Group | Storage Account | State Key |
|---|---|---|---|
| Dev | `rg-tfstate-aks-dev-ci36432` | `sttfstateaksdevci36432` | `aks-dev.terraform.tfstate` |
| Prod | `rg-tfstate-aks-prod-ci36432` | `sttfstateaksprodci36432` | `aks-prod.terraform.tfstate` |

## Naming Convention

`{resource_type}-{project}-{environment}-{region_short}`

Examples: `rg-poc-dev-eus`, `aks-poc-dev-eus`, `acr-poc-prod-weu`
